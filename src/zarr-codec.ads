with Interfaces;

--  Pure, provable little-endian scalar decoders.  Each takes an itemsize-long
--  slice of a decompressed chunk and returns one element; the array reader is
--  instantiated with the one matching its dtype, so the decode is fixed at
--  compile time (no per-element dispatch on the dtype).

package Zarr.Codec
  with SPARK_Mode
is

   function Decode_I4 (B : Byte_Array) return Interfaces.Integer_32
   with Pre => B'Length = 4;

   function Decode_I8 (B : Byte_Array) return Interfaces.Integer_64
   with Pre => B'Length = 8;

   --  The float reinterpret is outside the SPARK value model, so this one
   --  decoder's body is SPARK_Mode => Off (see the body).
   function Decode_F4 (B : Byte_Array) return Float
   with Pre => B'Length = 4;

end Zarr.Codec;
