with Ada.Strings.Unbounded;

--  Parsing of a Zarr v2 array header (.zarray).  The files are small and
--  machine-generated with a stable shape, so a targeted key/value scanner is
--  used rather than a full JSON parser (kept out of SPARK: text + I/O).

package Zarr.Metadata
  with SPARK_Mode => Off
is

   type Compressor_Kind is (No_Compressor, Blosc_Compressor, Zlib_Compressor);
   type Mem_Order is (C_Order, F_Order);

   type Array_Meta is record
      Rank       : Rank_Range := 1;
      Shape      : Extent_Array (1 .. Max_Rank) := [others => 0];
      Chunks     : Extent_Array (1 .. Max_Rank) := [others => 0];
      Dtype      : Dtype_Code := D_F4;
      Order      : Mem_Order := C_Order;
      Compressor : Compressor_Kind := No_Compressor;
      --  Chunk-key dimension separator ("." or "/"); default "." for v2.
      Separator  : Character := '.';
      --  Raw fill_value token (number / "NaN" / ... / "null"); empty if absent.
      Fill_Token : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Read and parse <Array_Dir>/.zarray.  Raises Unsupported for dtypes,
   --  ranks, orders, compressors or filters outside this reader's scope.
   function Read_Array_Meta (Array_Dir : String) return Array_Meta;

end Zarr.Metadata;
