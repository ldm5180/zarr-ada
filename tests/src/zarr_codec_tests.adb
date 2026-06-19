with AUnit.Assertions; use AUnit.Assertions;
with Interfaces;       use Interfaces;
with Zarr.Codec;
with Zarr.Fills;

package body Zarr_Codec_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Decode_I4 (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Zarr.Codec.Decode_I4 ([42, 0, 0, 0]) = 42, "little-endian 42");
      Assert (Zarr.Codec.Decode_I4 ([16#D2#, 16#04#, 0, 0]) = 1234, "1234");
      Assert
        (Zarr.Codec.Decode_I4 ([16#FF#, 16#FF#, 16#FF#, 16#FF#]) = -1,
         "all ones is -1 (signed)");
   end Test_Decode_I4;

   procedure Test_Decode_I8 (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Zarr.Codec.Decode_I8 ([100, 0, 0, 0, 0, 0, 0, 0]) = 100, "100");
      Assert
        (Zarr.Codec.Decode_I8 ([0, 0, 0, 0, 1, 0, 0, 0]) = 4_294_967_296,
         "2**32 spans the low/high words");
      Assert
        (Zarr.Codec.Decode_I8
           ([16#FF#, 16#FF#, 16#FF#, 16#FF#, 16#FF#, 16#FF#, 16#FF#, 16#FF#])
         = -1,
         "all ones is -1");
   end Test_Decode_I8;

   procedure Test_Decode_F4 (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      --  1.5 = 0x3FC00000, -2.25 = 0xC0100000 (both exact in float32).
      Assert
        (Zarr.Codec.Decode_F4 ([16#00#, 16#00#, 16#C0#, 16#3F#]) = 1.5, "1.5");
      Assert
        (Zarr.Codec.Decode_F4 ([16#00#, 16#00#, 16#10#, 16#C0#]) = -2.25,
         "-2.25");
   end Test_Decode_F4;

   procedure Test_NaN (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Zero : constant Float := 0.0;
      Q    : constant Float := Zarr.Fills.Quiet_NaN;
      D    : constant Float :=
        Zarr.Codec.Decode_F4 ([16#00#, 16#00#, 16#C0#, 16#7F#]);
   begin
      --  A NaN compares false against every ordinary value.
      Assert
        (not (Q = Zero) and not (Q < Zero) and not (Q > Zero),
         "Quiet_NaN is a NaN");
      Assert
        (not (D = Zero) and not (D < Zero) and not (D > Zero),
         "decoded 0x7FC00000 is a NaN");
   end Test_NaN;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine (T, Test_Decode_I4'Access, "Decode_I4 LE int32");
      Register_Routine (T, Test_Decode_I8'Access, "Decode_I8 LE int64");
      Register_Routine (T, Test_Decode_F4'Access, "Decode_F4 LE float32");
      Register_Routine (T, Test_NaN'Access, "NaN fill value and decode");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Zarr.Codec (little-endian scalar decode)");
   end Name;

end Zarr_Codec_Tests;
