with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Zarr.Metadata;
with Zarr.Indexing;
with Zarr.Stores;
with Zarr.Blosc;

package body Zarr.Arrays is

   use type Metadata.Mem_Order;
   use type Metadata.Compressor_Kind;

   function To_Nat (V : Long_Long_Integer) return Natural is
   begin
      if V < 0 or else V > Long_Long_Integer (Natural'Last) then
         raise Unsupported with "array dimension too large";
      end if;
      return Natural (V);
   end To_Nat;

   --  "3.2" for chunk coordinate (3, 2) with separator '.'; "0" for (0).
   function Chunk_Key (Idx : Extent_Array; Separator : Character) return String
   is
      Result : Unbounded_String;
   begin
      for D in Idx'Range loop
         if D /= Idx'First then
            Append (Result, Separator);
         end if;
         declare
            Img : constant String := Natural'Image (Idx (D));
         begin
            Append (Result, Img (Img'First + 1 .. Img'Last));
         end;
      end loop;
      return To_String (Result);
   end Chunk_Key;

   --  Mixed-radix odometer; False once it wraps past the last cell.
   function Increment
     (C : in out Extent_Array; Bounds : Extent_Array) return Boolean is
   begin
      for D in reverse C'Range loop
         if C (D) + 1 < Bounds (D) then
            C (D) := C (D) + 1;
            return True;
         else
            C (D) := 0;
         end if;
      end loop;
      return False;
   end Increment;

   --  Copy a decompressed chunk's in-bounds elements into the result, trimming
   --  the padding zarr stores in edge chunks.
   procedure Scatter
     (Raw    : Byte_Array;
      CIdx   : Extent_Array;
      Chunks : Extent_Array;
      Shape  : Extent_Array;
      Result : in out Array_Data)
   is
      R         : constant Rank_Range := CIdx'Length;
      W         : Extent_Array (1 .. R) := [others => 0];   --  within-chunk
      G         : Extent_Array (1 .. R);                    --  global coord
      In_Bounds : Boolean;
   begin
      loop
         In_Bounds := True;
         for D in 1 .. R loop
            G (D) := CIdx (D) * Chunks (D) + W (D);
            if G (D) >= Shape (D) then
               In_Bounds := False;
            end if;
         end loop;

         if In_Bounds then
            declare
               LG  : constant Natural := To_Nat (Indexing.Linear (G, Shape));
               LC  : constant Natural := To_Nat (Indexing.Linear (W, Chunks));
               Off : constant Natural := LC * Itemsize;
            begin
               Result.Items (LG + 1) :=
                 Decode (Raw (Off .. Off + Itemsize - 1));
            end;
         end if;

         exit when not Increment (W, Chunks);
      end loop;
   end Scatter;

   function Load (Store : String; Name : String) return Array_Data is
      Dir      : constant String := Store & "/" & Name;
      M        : constant Metadata.Array_Meta :=
        Metadata.Read_Array_Meta (Dir);
      R        : constant Rank_Range := M.Rank;
      Shape    : constant Extent_Array := M.Shape (1 .. R);
      Chunks   : constant Extent_Array := M.Chunks (1 .. R);
      Fill_Val : constant Element := Parse_Fill (To_String (M.Fill_Token), Fill);
   begin
      if M.Dtype /= Expect then
         raise Unsupported with "dtype mismatch reading " & Name;
      end if;
      if M.Order /= Metadata.C_Order then
         raise Unsupported with "only C (row-major) order is supported";
      end if;

      --  Empty array (some extent is 0): no chunks to read, no index math.
      if (for some D in Shape'Range => Shape (D) = 0) then
         return Result : Array_Data (Length => 0, Rank => R) do
            Result.Shape := Shape;
         end return;
      end if;

      declare
         N      : constant Natural := To_Nat (Indexing.Product (Shape));
         CElems : constant Natural := To_Nat (Indexing.Product (Chunks));
      begin
         if CElems > Natural'Last / Itemsize then
            raise Unsupported with "chunk too large to buffer";
         end if;

         return Result : Array_Data (Length => N, Rank => R) do
            Result.Shape := Shape;
            Result.Items := [others => Fill_Val];
            declare
               CBytes  : constant Natural := CElems * Itemsize;
               NChunks : Extent_Array (1 .. R);
               CIdx    : Extent_Array (1 .. R) := [others => 0];
               Raw     : Byte_Array (0 .. CBytes - 1);
            begin
               for D in 1 .. R loop
                  NChunks (D) := Indexing.Ceil_Div (Shape (D), Chunks (D));
               end loop;

               loop
                  declare
                     Path : constant String :=
                       Dir & "/" & Chunk_Key (CIdx, M.Separator);
                  begin
                     if Stores.Exists (Path) then
                        declare
                           Comp : constant Byte_Array :=
                             Stores.Read_File (Path);
                        begin
                           if M.Compressor = Metadata.Blosc_Compressor then
                              Blosc.Decompress (Comp, Raw);
                           elsif Comp'Length = Raw'Length then
                              Raw := Comp;
                           else
                              raise Decompress_Error
                                with "uncompressed chunk size mismatch";
                           end if;
                           Scatter (Raw, CIdx, Chunks, Shape, Result);
                        end;
                     end if;
                  --  Missing chunk: leave the Fill already in place.
                  end;
                  exit when not Increment (CIdx, NChunks);
               end loop;
            end;
         end return;
      end;
   end Load;

   function Element_At (A : Array_Data; Coord : Extent_Array) return Element is
      --  Slide Coord to 1 .. Rank so it lines up with A.Shape regardless of
      --  the actual'First (and so a length mismatch is caught here, cleanly).
      C : constant Extent_Array (1 .. A.Rank) := Coord;
   begin
      for D in 1 .. A.Rank loop
         if C (D) >= A.Shape (D) then
            raise Constraint_Error with "Element_At: coordinate out of range";
         end if;
      end loop;
      return A.Items (To_Nat (Indexing.Linear (C, A.Shape)) + 1);
   end Element_At;

end Zarr.Arrays;
