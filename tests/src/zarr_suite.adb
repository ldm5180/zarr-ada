with AUnit.Test_Cases;

with Zarr_Codec_Tests;
with Zarr_Indexing_Tests;
with Zarr_Reader_Tests;

package body Zarr_Suite is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (Result,
         AUnit.Test_Cases.Test_Case_Access'(new Zarr_Codec_Tests.Test));
      AUnit.Test_Suites.Add_Test
        (Result,
         AUnit.Test_Cases.Test_Case_Access'(new Zarr_Indexing_Tests.Test));
      AUnit.Test_Suites.Add_Test
        (Result,
         AUnit.Test_Cases.Test_Case_Access'(new Zarr_Reader_Tests.Test));
      return Result;
   end Suite;

end Zarr_Suite;
