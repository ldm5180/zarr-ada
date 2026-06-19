with Zarr.Arrays;
with Zarr.Codec;
with Zarr.Fills;
with Interfaces;

--  Reader for "<i4" (little-endian int32) arrays.

package Zarr.I32 is new
  Zarr.Arrays
    (Element    => Interfaces.Integer_32,
     Itemsize   => 4,
     Expect     => Zarr.D_I4,
     Fill       => 0,
     Decode     => Zarr.Codec.Decode_I4,
     Parse_Fill => Zarr.Fills.I32_Fill);
