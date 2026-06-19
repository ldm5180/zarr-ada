with Interfaces.C;
with System;

package body Zarr.Blosc is

   use Interfaces.C;

   --  int blosc_decompress(const void *src, void *dest, size_t destsize);
   --  Returns the number of bytes written (> 0), or < 0 on error.
   function C_Decompress
     (Src, Dest : System.Address; Destsize : size_t) return int
     with Import, Convention => C, External_Name => "blosc_decompress";

   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array) is
      RC : int;
   begin
      if Dst'Length = 0 then
         return;
      end if;
      RC := C_Decompress (Src'Address, Dst'Address, size_t (Dst'Length));
      if Long_Integer (RC) /= Long_Integer (Dst'Length) then
         raise Decompress_Error
           with "blosc_decompress returned" & int'Image (RC)
                & " (expected" & Natural'Image (Dst'Length) & ")";
      end if;
   end Decompress;

end Zarr.Blosc;
