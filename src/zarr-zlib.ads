--  Thin binding to the system zlib (zlib1g-dev).  Inflates a zlib- or
--  gzip-wrapped DEFLATE stream via inflateInit2 with windowBits = 47, which
--  auto-detects both wrappers, so one path serves the numcodecs "zlib" and
--  "gzip" compressors.  A second external, non-SPARK boundary, like
--  Zarr.Blosc.
package Zarr.Zlib
  with SPARK_Mode => Off
is

   pragma Linker_Options ("-lz");

   --  Decompress a zlib- or gzip-framed buffer into Dst.  Dst'Length must be
   --  the exact uncompressed size.  Raises Decompress_Error on failure or an
   --  unexpected output size.
   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array);

end Zarr.Zlib;
