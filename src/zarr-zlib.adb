with Interfaces.C;
with Interfaces.C.Strings;
with System;

package body Zarr.Zlib is

   use Interfaces.C;

   --  Mirrors C's z_stream.  Convention C gives the matching LP64 layout and
   --  padding; the fields default to zero/null so zlib uses its own allocator.
   type Z_Stream is record
      Next_In   : System.Address := System.Null_Address;
      Avail_In  : unsigned := 0;
      Total_In  : unsigned_long := 0;
      Next_Out  : System.Address := System.Null_Address;
      Avail_Out : unsigned := 0;
      Total_Out : unsigned_long := 0;
      Msg       : System.Address := System.Null_Address;
      State     : System.Address := System.Null_Address;
      Zalloc    : System.Address := System.Null_Address;
      Zfree     : System.Address := System.Null_Address;
      Opaque    : System.Address := System.Null_Address;
      Data_Type : int := 0;
      Adler     : unsigned_long := 0;
      Reserved  : unsigned_long := 0;
   end record
   with Convention => C;

   function Zlib_Version return Interfaces.C.Strings.chars_ptr
   with Import, Convention => C, External_Name => "zlibVersion";

   --  inflateInit2 is a macro for inflateInit2_(strm, bits, version, sizeof).
   function Inflate_Init2
     (Strm        : access Z_Stream;
      Window_Bits : int;
      Version     : Interfaces.C.Strings.chars_ptr;
      Stream_Size : int) return int
   with Import, Convention => C, External_Name => "inflateInit2_";

   function Inflate (Strm : access Z_Stream; Flush : int) return int
   with Import, Convention => C, External_Name => "inflate";

   --  Imported as a procedure: inflateEnd's int result is just a cleanup
   --  status we always ignore, so this lets the call be a plain statement.
   procedure Inflate_End (Strm : access Z_Stream)
   with Import, Convention => C, External_Name => "inflateEnd";

   Z_Finish     : constant int := 4;
   Z_OK         : constant int := 0;
   Z_Stream_End : constant int := 1;
   Auto_Detect  : constant int := 47;  --  15 (max window) + 32 (zlib or gzip)

   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array) is
      Strm : aliased Z_Stream;
      RC   : int;
   begin
      if Dst'Length = 0 then
         return;
      end if;
      if Src'Length = 0 then
         raise Decompress_Error with "empty zlib/gzip chunk";
      end if;

      Strm.Next_In := Src'Address;
      Strm.Avail_In := unsigned (Src'Length);
      Strm.Next_Out := Dst'Address;
      Strm.Avail_Out := unsigned (Dst'Length);

      RC :=
        Inflate_Init2
          (Strm'Access,
           Auto_Detect,
           Zlib_Version,
           int (Strm'Size / System.Storage_Unit));
      if RC /= Z_OK then
         raise Decompress_Error with "inflateInit2 failed:" & int'Image (RC);
      end if;

      RC := Inflate (Strm'Access, Z_Finish);
      Inflate_End (Strm'Access);

      if RC /= Z_Stream_End then
         raise Decompress_Error with "inflate failed:" & int'Image (RC);
      end if;
      if Long_Integer (Strm.Total_Out) /= Long_Integer (Dst'Length) then
         raise Decompress_Error
           with
             "inflate size mismatch (got"
             & unsigned_long'Image (Strm.Total_Out)
             & ")";
      end if;
   end Decompress;

end Zarr.Zlib;
