with Interfaces;
with Ada.Unchecked_Conversion;

--  Fill values, kept out of SPARK: building a NaN/Inf means reinterpreting a
--  bit pattern as a float, which is not in the SPARK value model.  Also parses
--  a Zarr fill_value token into an element value.  Only the (non-SPARK) typed
--  array readers use these.

package Zarr.Fills
  with SPARK_Mode => Off
is

   --  IEEE-754 single-precision quiet NaN: zarr's default float fill value.
   Quiet_NaN : constant Float;

   --  Convert a Zarr fill_value token -- the raw JSON scalar text: a number,
   --  one of "NaN"/"Infinity"/"-Infinity", or "" / "null" -- to an element
   --  value.  An empty, null, or unparseable token yields Default.
   function Float_Fill (Token : String; Default : Float) return Float;

   function I32_Fill
     (Token : String; Default : Interfaces.Integer_32)
      return Interfaces.Integer_32;

   function I64_Fill
     (Token : String; Default : Interfaces.Integer_64)
      return Interfaces.Integer_64;

private

   function To_Float is new
     Ada.Unchecked_Conversion (Interfaces.Unsigned_32, Float);
   Quiet_NaN : constant Float := To_Float (16#7FC0_0000#);

end Zarr.Fills;
