--  Thin binding to the system Blosc library (libblosc-dev).  One call,
--  blosc_decompress, undoes the whole Blosc v1 container: the inner codec
--  (zstd, in the spxw data) and the byte/bit shuffle filter.  This is the one
--  external, non-SPARK boundary of the reader.

package Zarr.Blosc
  with SPARK_Mode => Off
is

   pragma Linker_Options ("-lblosc");

   --  Decompress a Blosc-framed buffer into Dst.  Dst'Length must be the exact
   --  uncompressed size (elements * itemsize for the chunk).  Raises
   --  Decompress_Error if libblosc fails or returns a different size.
   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array);

end Zarr.Blosc;
