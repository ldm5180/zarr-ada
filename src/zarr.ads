with Interfaces;

--  Root of a minimal reader for Zarr v2 stores.  Scope is deliberately small:
--  C (row-major) order, little-endian numeric dtypes, 1-D and 2-D arrays, with
--  chunks decompressed by the system Blosc library.  See README.md.

package Zarr
  with SPARK_Mode
is

   --  Highest array rank supported.  32 matches numpy's historical dimension
   --  limit; an array with more dimensions raises Unsupported.  The reader is
   --  rank-generic -- Zarr.Indexing proves the arbitrary-rank index arithmetic
   --  overflow-free by saturating, so this is just a sizing bound.
   Max_Rank : constant := 32;

   subtype Rank_Range is Positive range 1 .. Max_Rank;

   --  A raw byte and a 0-based byte buffer (laid out for passing to C).
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;

   --  Per-dimension sizes: an array shape, a chunk shape, or a coordinate.
   type Extent_Array is array (Rank_Range range <>) of Natural;

   --  The numpy dtypes this reader decodes (all little-endian).
   type Dtype_Code is (D_F4, D_I4, D_I8);

   function Itemsize (D : Dtype_Code) return Positive
   is (case D is
         when D_F4 => 4,
         when D_I4 => 4,
         when D_I8 => 8);

   --  Well-formed store, but using a feature this reader does not handle.
   Unsupported      : exception;
   --  Filesystem error while reading the store.
   IO_Error         : exception;
   --  libblosc reported a failure (or an unexpected output size).
   Decompress_Error : exception;

end Zarr;
