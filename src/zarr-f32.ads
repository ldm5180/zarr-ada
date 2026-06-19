with Zarr.Arrays;
with Zarr.Codec;
with Zarr.Fills;

--  Reader for "<f4" (little-endian float32) arrays.

package Zarr.F32 is new
  Zarr.Arrays
    (Element  => Float,
     Itemsize => 4,
     Expect   => Zarr.D_F4,
     Fill     => Zarr.Fills.Quiet_NaN,
     Decode   => Zarr.Codec.Decode_F4);
