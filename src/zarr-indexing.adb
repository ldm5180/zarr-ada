package body Zarr.Indexing
  with SPARK_Mode
is

   Max_Nat : constant Long_Long_Integer := Long_Long_Integer (Natural'Last);

   --  A + (B - 1), not A + B - 1: the regrouping keeps the intermediate sum
   --  within Integer (the precondition bounds A by Integer'Last - B).
   function Ceil_Div (A, B : Positive) return Positive
   is ((A + (B - 1)) / B);

   function Product (E : Extent_Array) return Long_Long_Integer is
      Acc : Long_Long_Integer := 1;
   begin
      for I in E'Range loop
         pragma Loop_Invariant (Acc >= 1 and then Acc <= Overflow_Sentinel);
         --  Once saturated (Acc > Max_Nat) we stop multiplying; otherwise
         --  Acc <= Max_Nat and E (I) <= Max_Nat, so the product stays well
         --  within Long_Long_Integer before being clamped.
         if Acc <= Max_Nat then
            Acc := Acc * Long_Long_Integer (E (I));
            if Acc > Overflow_Sentinel then
               Acc := Overflow_Sentinel;
            end if;
         end if;
      end loop;
      return Acc;
   end Product;

   function Linear (Coord, Shape : Extent_Array) return Long_Long_Integer is
      Acc : Long_Long_Integer := 0;
   begin
      for I in Coord'Range loop
         pragma Loop_Invariant (Acc >= 0 and then Acc <= Overflow_Sentinel);
         if Acc <= Max_Nat then
            Acc :=
              Acc
              * Long_Long_Integer (Shape (I))
              + Long_Long_Integer (Coord (I));
            if Acc > Overflow_Sentinel then
               Acc := Overflow_Sentinel;
            end if;
         end if;
      end loop;
      return Acc;
   end Linear;

end Zarr.Indexing;
