with Interfaces.C;
with System;

package body Zarr.Bz2 is

   use Interfaces.C;

   Bz_OK : constant int := 0;

   --  int BZ2_bzBuffToBuffDecompress(char* dest, unsigned* destLen,
   --      char* source, unsigned sourceLen, int small, int verbosity);
   --  destLen is in/out: the dest capacity in, the bytes written out.
   function Buff_To_Buff_Decompress
     (Dest       : System.Address;
      Dest_Len   : access unsigned;
      Source     : System.Address;
      Source_Len : unsigned;
      Small      : int;
      Verbosity  : int) return int
     with Import,
          Convention    => C,
          External_Name => "BZ2_bzBuffToBuffDecompress";

   procedure Decompress (Src : Byte_Array; Dst : out Byte_Array) is
      Dest_Len : aliased unsigned := unsigned (Dst'Length);
      RC       : int;
   begin
      if Dst'Length = 0 then
         return;
      end if;
      if Src'Length = 0 then
         raise Decompress_Error with "empty bz2 chunk";
      end if;

      RC :=
        Buff_To_Buff_Decompress
          (Dst'Address,
           Dest_Len'Access,
           Src'Address,
           unsigned (Src'Length),
           0,
           0);

      if RC /= Bz_OK then
         raise Decompress_Error with "bz2 decompress failed:" & int'Image (RC);
      end if;
      if Long_Integer (Dest_Len) /= Long_Integer (Dst'Length) then
         raise Decompress_Error
           with "bz2 size mismatch (got" & unsigned'Image (Dest_Len) & ")";
      end if;
   end Decompress;

end Zarr.Bz2;
