with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Zarr.Stores;

package body Zarr.Metadata is

   --  Index just past the colon following "Key" (0 if the key is absent).
   function After_Key (S : String; Key : String) return Natural is
      Q : constant String := '"' & Key & '"';
      P : Natural := Index (S, Q);
   begin
      if P = 0 then
         return 0;
      end if;
      P := P + Q'Length;
      while P <= S'Last
        and then (S (P) = ' '
                  or else S (P) = ':'
                  or else S (P) = ASCII.HT
                  or else S (P) = ASCII.LF
                  or else S (P) = ASCII.CR)
      loop
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

   --  The integers of the [...] starting at/after Start.
   procedure Read_Int_Array
     (S : String; Start : Natural; E : out Extent_Array; Count : out Natural)
   is
      I : Natural := Start;
   begin
      E := [others => 0];
      Count := 0;
      while I <= S'Last and then S (I) /= '[' loop
         I := I + 1;
      end loop;
      I := I + 1;  --  past '['
      loop
         while I <= S'Last
           and then (S (I) = ' '
                     or else S (I) = ','
                     or else S (I) = ASCII.HT
                     or else S (I) = ASCII.LF
                     or else S (I) = ASCII.CR)
         loop
            I := I + 1;
         end loop;
         exit when I > S'Last or else S (I) = ']';
         declare
            V : Natural := 0;
         begin
            while I <= S'Last and then S (I) in '0' .. '9' loop
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
   begin
      Read_Int_Array (Text, After_Key (Text, "shape"), M.Shape, Sc);
      Read_Int_Array (Text, After_Key (Text, "chunks"), M.Chunks, Cc);
      if Sc = 0 or else Sc > Max_Rank or else Sc /= Cc then
         raise Unsupported
           with "unsupported rank (" & Natural'Image (Sc) & " dims)";
      end if;
      M.Rank := Sc;

      M.Dtype := To_Dtype (Read_String (Text, After_Key (Text, "dtype")));

      M.Order :=
        (if Read_String (Text, After_Key (Text, "order")) = "C"
         then C_Order
         else F_Order);

      P := After_Key (Text, "compressor");
      if P = 0 or else (P + 3 <= Text'Last and then Text (P .. P + 3) = "null")
      then
         M.Compressor := No_Compressor;
      else
         M.Compressor := Blosc_Compressor;
      end if;

      return M;
   end Read_Array_Meta;

end Zarr.Metadata;
