--  Thin binding to the system bzip2 (libbz2-dev).  One call,
--  BZ2_bzBuffToBuffDecompress, decodes a bzip2 stream -- the numcodecs "bz2"
--  compressor.  Another external, non-SPARK boundary, like Zarr.Blosc.
package Zarr.Bz2
  with SPARK_Mode => Off
is

   pragma Linker_Options ("-lbz2");

   --  Decompress a bzip2 buffer into Dst.  Dst'Length must be the exact
   --  uncompressed size.  Raises Decompress_Error on failure or a size
   --  mismatch.
   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array);

end Zarr.Bz2;
