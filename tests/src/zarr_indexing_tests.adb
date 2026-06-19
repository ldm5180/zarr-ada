with AUnit.Assertions; use AUnit.Assertions;
with Zarr.Indexing;    use Zarr.Indexing;

package body Zarr_Indexing_Tests is

   use AUnit.Test_Cases.Registration;

   procedure Test_Ceil_Div (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Ceil_Div (6, 3) = 2, "exact division");
      Assert (Ceil_Div (5, 3) = 2, "rounds up");
      Assert (Ceil_Div (4, 3) = 2, "rounds up");
      --  The spxw chunk grids: 149/38 -> 4, 27299/3413 -> 8.
      Assert (Ceil_Div (149, 38) = 4, "149 over 38");
      Assert (Ceil_Div (27_299, 3_413) = 8, "27299 over 3413");
   end Test_Ceil_Div;

   procedure Test_Product (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Product ([7]) = 7, "1-D product");
      Assert (Product ([5, 4]) = 20, "2-D product");
      Assert (Product ([2, 3, 4]) = 24, "3-D product (rank-generic)");
      Assert (Product ([27_299, 149]) = 4_067_551, "spxw element count");
   end Test_Product;

   procedure Test_Linear (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Linear ([6], [7]) = 6, "1-D offset");
      Assert (Linear ([0, 3], [5, 4]) = 3, "row 0, col 3");
      Assert (Linear ([1, 0], [5, 4]) = 4, "row 1 starts after row 0");
      Assert (Linear ([4, 3], [5, 4]) = 19, "last element");
      Assert (Linear ([1, 2, 3], [2, 3, 4]) = 23, "3-D offset (rank-generic)");
      Assert (Linear ([1, 2, 0], [2, 3, 4]) = 20, "3-D offset, edge");
   end Test_Linear;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine (T, Test_Ceil_Div'Access, "Ceil_Div chunk-grid sizing");
      Register_Routine (T, Test_Product'Access, "Product element counts");
      Register_Routine (T, Test_Linear'Access, "Linear row-major offsets");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Zarr.Indexing (chunk-grid arithmetic)");
   end Name;

end Zarr_Indexing_Tests;
