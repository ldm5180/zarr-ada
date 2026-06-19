with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Zarr.Stores;

package body Zarr.Metadata is

   function Is_Space (C : Character) return Boolean
   is (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   --  True when the JSON value at P is an empty array "[]" (spaces tolerated).
   function Empty_Array_At (S : String; P : Natural) return Boolean is
      Q : Natural := P + 1;
   begin
      if P = 0 or else P > S'Last or else S (P) /= '[' then
         return False;
      end if;
      while Q <= S'Last and then Is_Space (S (Q)) loop
         Q := Q + 1;
      end loop;
      return Q <= S'Last and then S (Q) = ']';
   end Empty_Array_At;

   --  Index just past the colon following "Key" (0 if the key is absent).
   function After_Key (S : String; Key : String) return Natural is
      Q : constant String := '"' & Key & '"';
      P : Natural := Index (S, Q);
   begin
      if P = 0 then
         return 0;
      end if;
      P := P + Q'Length;
      while P <= S'Last and then (Is_Space (S (P)) or else S (P) = ':') loop
         P := P + 1;
      end loop;
      return P;
   end After_Key;

   --  The contents of the "..." starting at Start.
   function Read_String (S : String; Start : Natural) return String is
      I : Natural := Start;
      J : Natural;
   begin
      if I = 0 or else I > S'Last or else S (I) /= '"' then
         return "";
      end if;
      I := I + 1;
      J := I;
      while J <= S'Last and then S (J) /= '"' loop
         J := J + 1;
      end loop;
      return S (I .. J - 1);
   end Read_String;

   --  The raw JSON scalar value at Start: a quoted string's contents, or an
   --  unquoted run (number / null / true / false).  "" if the key was absent.
   function Read_Value (S : String; Start : Natural) return String is
      J : Natural;
   begin
      if Start = 0 or else Start > S'Last then
         return "";
      end if;
      if S (Start) = '"' then
         return Read_String (S, Start);
      end if;
      J := Start;
      while J <= S'Last
        and then S (J) /= ','
        and then S (J) /= '}'
        and then S (J) /= ']'
        and then not Is_Space (S (J))
      loop
         J := J + 1;
      end loop;
      return S (Start .. J - 1);
   end Read_Value;

   --  The integers of the [...] starting at/after Start.  Count = 0 when the
   --  key is absent (Start = 0) so the caller can raise a clean error.
   procedure Read_Int_Array
     (S : String; Start : Natural; E : out Extent_Array; Count : out Natural)
   is
      I : Natural := Start;
   begin
      E := [others => 0];
      Count := 0;
      if Start = 0 or else Start > S'Last then
         return;
      end if;
      while I <= S'Last and then S (I) /= '[' loop
         I := I + 1;
      end loop;
      I := I + 1;  --  past '['
      loop
         while I <= S'Last and then (Is_Space (S (I)) or else S (I) = ',') loop
            I := I + 1;
         end loop;
         exit when I > S'Last or else S (I) = ']';
         declare
            V : Natural := 0;
         begin
            while I <= S'Last and then S (I) in '0' .. '9' loop
               if V > (Natural'Last - 9) / 10 then
                  raise Unsupported with "array dimension too large";
               end if;
               V := V * 10 + (Character'Pos (S (I)) - Character'Pos ('0'));
               I := I + 1;
            end loop;
            Count := Count + 1;
            if Count <= Max_Rank then
               E (Count) := V;
            end if;
         end;
      end loop;
   end Read_Int_Array;

   function To_Dtype (S : String) return Dtype_Code is
   begin
      if S = "<f4" then
         return D_F4;
      elsif S = "<i4" then
         return D_I4;
      elsif S = "<i8" then
         return D_I8;
      else
         raise Unsupported with "unsupported dtype """ & S & """";
      end if;
   end To_Dtype;

   function Read_Array_Meta (Array_Dir : String) return Array_Meta is
      Text   : constant String :=
        Zarr.Stores.Read_Text (Array_Dir & "/.zarray");
      M      : Array_Meta;
      Sc, Cc : Natural;
      P      : Natural;
      Sep    : constant String :=
        Read_String (Text, After_Key (Text, "dimension_separator"));
   begin
      Read_Int_Array (Text, After_Key (Text, "shape"), M.Shape, Sc);
      Read_Int_Array (Text, After_Key (Text, "chunks"), M.Chunks, Cc);
      if Sc = 0 or else Sc > Max_Rank or else Sc /= Cc then
         raise Unsupported
           with "unsupported rank (" & Natural'Image (Sc) & " dims)";
      end if;
      M.Rank := Sc;

      --  A chunk extent of 0 would divide by zero when sizing the chunk grid.
      for D in 1 .. M.Rank loop
         if M.Chunks (D) = 0 then
            raise Unsupported with "zero chunk extent";
         end if;
      end loop;

      M.Dtype := To_Dtype (Read_String (Text, After_Key (Text, "dtype")));

      M.Order :=
        (if Read_String (Text, After_Key (Text, "order")) = "C"
         then C_Order
         else F_Order);

      if Sep'Length >= 1 then
         M.Separator := Sep (Sep'First);
      end if;

      M.Fill_Token :=
        To_Unbounded_String
          (Read_Value (Text, After_Key (Text, "fill_value")));

      --  Filters (pre-compression transforms) are not reversed, so only an
      --  absent or empty filter list can be read correctly.
      P := After_Key (Text, "filters");
      if P /= 0
        and then P <= Text'Last
        and then Text (P) = '['
        and then not Empty_Array_At (Text, P)
      then
         raise Unsupported with "filters are not supported";
      end if;

      --  Compressor: null = none; "blosc" via libblosc (which handles its
      --  inner codec -- zstd/lz4/...); "zlib"/"gzip" via libz; "bz2" via
      --  libbz2; anything else (lzma, a bare lz4, ...) is rejected rather than
      --  mis-decoded.
      P := After_Key (Text, "compressor");
      if P = 0 or else (P <= Text'Last and then Text (P) = 'n') then
         M.Compressor := No_Compressor;
      else
         declare
            Id : constant String := Read_String (Text, After_Key (Text, "id"));
         begin
            if Id = "blosc" then
               M.Compressor := Blosc_Compressor;
            elsif Id = "zlib" or else Id = "gzip" then
               M.Compressor := Zlib_Compressor;
            elsif Id = "bz2" then
               M.Compressor := Bz2_Compressor;
            else
               raise Unsupported
                 with "compressor """ & Id & """ is not supported";
            end if;
         end;
      end if;

      return M;
   end Read_Array_Meta;

end Zarr.Metadata;
