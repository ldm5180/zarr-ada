with Interfaces;
with Ada.Unchecked_Conversion;

--  Float fill values, kept out of SPARK: building a NaN means reinterpreting a
--  bit pattern as a float, which is not in the SPARK value model.  Only the
--  (non-SPARK) typed array readers use these.
package Zarr.Fills with SPARK_Mode => Off is

   --  IEEE-754 single-precision quiet NaN: the float fill value zarr writes.
   Quiet_NaN : constant Float;

private

   function To_Float is
     new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, Float);
   Quiet_NaN : constant Float := To_Float (16#7FC0_0000#);

end Zarr.Fills;
