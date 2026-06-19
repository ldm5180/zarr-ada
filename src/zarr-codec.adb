with Ada.Unchecked_Conversion;

package body Zarr.Codec
  with SPARK_Mode
is

   use Interfaces;

   pragma Assert (Standard.Float'Size = 32);

   --  Assemble little-endian bytes by iterating B'Range, so every index is
   --  valid by construction and no B'First + k offset can overflow.
   function LE32 (B : Byte_Array) return Unsigned_32 with Pre => B'Length = 4
   is
      R : Unsigned_32 := 0;
   begin
      for I in B'Range loop
         R := R or Shift_Left (Unsigned_32 (B (I)), 8 * Natural (I - B'First));
      end loop;
      return R;
   end LE32;

   function LE64 (B : Byte_Array) return Unsigned_64 with Pre => B'Length = 8
   is
      R : Unsigned_64 := 0;
   begin
      for I in B'Range loop
         R := R or Shift_Left (Unsigned_64 (B (I)), 8 * Natural (I - B'First));
      end loop;
      return R;
   end LE64;

   function To_I32 is new Ada.Unchecked_Conversion (Unsigned_32, Integer_32);
   function To_I64 is new Ada.Unchecked_Conversion (Unsigned_64, Integer_64);

   function Decode_I4 (B : Byte_Array) return Integer_32
   is (To_I32 (LE32 (B)));

   function Decode_I8 (B : Byte_Array) return Integer_64
   is (To_I64 (LE64 (B)));

   --  Reinterpreting 32 bits as a float is the one thing SPARK cannot model
   --  (floats have invalid bit patterns), so this single body is excluded.
   function Decode_F4 (B : Byte_Array) return Float with SPARK_Mode => Off is
      function To_F32 is new Ada.Unchecked_Conversion (Unsigned_32, Float);
   begin
      return To_F32 (LE32 (B));
   end Decode_F4;

end Zarr.Codec;
