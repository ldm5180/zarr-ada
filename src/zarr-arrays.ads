--  The typed array reader.  Instantiating it fixes, at compile time, the
--  element type, its byte size, and the little-endian decode for one dtype --
--  so reading a chunk involves no run-time dispatch on the dtype.  See the
--  ready-made instances Zarr.F32, Zarr.I32, Zarr.I64.

generic
   type Element is private;
   Itemsize : Positive;                 --  bytes per element (matches dtype)
   Expect : Dtype_Code;               --  dtype this instance accepts
   Fill : Element;                  --  fallback fill when none in metadata
   with function Decode (B : Byte_Array) return Element;
   --  Convert a Zarr fill_value token to an element (Default if empty/null).
   with function Parse_Fill (Token : String; Default : Element) return Element;
package Zarr.Arrays with SPARK_Mode => Off is

   type Element_Sequence is array (Positive range <>) of Element;

   --  A whole array materialised in memory, row-major (C order).
   type Array_Data
     (Length : Natural;
      Rank   : Rank_Range)
   is record
      Shape : Extent_Array (1 .. Rank);
      Items : Element_Sequence (1 .. Length);
   end record;

   --  Load array Name from the store rooted at Store (the .zarr directory).
   --  Raises Unsupported on a dtype/order mismatch, IO_Error or
   --  Decompress_Error on a bad store.
   function Load (Store : String; Name : String) return Array_Data;

   --  Element at a 0-based coordinate (length must equal the array's rank).
   function Element_At (A : Array_Data; Coord : Extent_Array) return Element
   with Pre => Coord'Length = A.Rank;

end Zarr.Arrays;
