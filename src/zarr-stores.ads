--  Filesystem access to a directory-backed store.  Isolated here so the rest
--  of the reader stays free of I/O (and, where marked, stays in SPARK).

package Zarr.Stores
  with SPARK_Mode => Off
is

   function Exists (Path : String) return Boolean;

   --  Whole-file reads.  Raise IO_Error on any filesystem failure.
   function Read_File (Path : String) return Byte_Array;
   function Read_Text (Path : String) return String;

end Zarr.Stores;
