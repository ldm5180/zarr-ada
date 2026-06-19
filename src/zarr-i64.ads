with Zarr.Arrays;
with Zarr.Codec;
with Interfaces;

--  Reader for "<i8" (little-endian int64) arrays.
package Zarr.I64 is new Zarr.Arrays
  (Element  => Interfaces.Integer_64,
   Itemsize => 8,
   Expect   => Zarr.D_I8,
   Fill     => 0,
   Decode   => Zarr.Codec.Decode_I8);
