with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;
with Interfaces;       use Interfaces;
with Zarr;
with Zarr.F32;
with Zarr.I32;
with Zarr.I64;

--  Reads a real spxw option-chain store and checks the values against the
--  ground truth dumped from python-zarr.  Pass a .zarr path as argv(1) to read
--  a different store; otherwise a sample from ~/git/retrotester is used.

procedure Read_Spxw is

   Default_Store : constant String :=
     "/home/lenny/git/retrotester/data/spxw/2023/20230807_C.zarr";
   Store         : constant String :=
     (if Argument_Count >= 1 then Argument (1) else Default_Store);

   Failures : Natural := 0;

   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Put_Line ("  ok   " & Msg);
      else
         Put_Line ("  FAIL " & Msg);
         Failures := Failures + 1;
      end if;
   end Check;

   function Near (A, B : Float) return Boolean
   is (abs (A - B) <= 0.0001 * (1.0 + abs B));

begin
   Put_Line ("store: " & Store);
   New_Line;

   Put_Line ("strike  <i4>  (149,):");
   declare
      A : constant Zarr.I32.Array_Data := Zarr.I32.Load (Store, "strike");
   begin
      Check (A.Rank = 1 and then A.Shape (1) = 149, "shape = (149)");
      Check
        (A.Items (1) = 1200 and then A.Items (5) = 2000,
         "strike[:5] = 1200,1400,1600,1800,2000");
      Check (A.Items (A.Length) = 5800, "strike[-1] = 5800");
   end;
   New_Line;

   Put_Line ("tick    <i8>  (27299,):");
   declare
      A : constant Zarr.I64.Array_Data := Zarr.I64.Load (Store, "tick");
   begin
      Check (A.Shape (1) = 27299, "shape = (27299)");
      Check (A.Items (1) = 0 and then A.Items (3) = 120, "tick[:3]=0,60,120");
      Check (A.Items (A.Length) = 1232939, "tick[-1] = 1232939");
   end;
   New_Line;

   Put_Line ("ask/iv/delta  <f4>  (27299,149)  chunks (3413,38):");
   declare
      use Zarr.F32;
      Ask : constant Array_Data := Load (Store, "ask");
      Iv  : constant Array_Data := Load (Store, "iv");
      Dl  : constant Array_Data := Load (Store, "delta");
   begin
      Check
        (Ask.Rank = 2
         and then Ask.Shape (1) = 27299
         and then Ask.Shape (2) = 149,
         "ask shape = (27299,149)");
      Check
        (Near (Element_At (Ask, [0, 0]), 3355.6001), "ask[0,0] = 3355.6001");
      Check (Near (Element_At (Ask, [0, 3]), 2756.8000), "ask[0,3] = 2756.8");
      Check
        (Near (Element_At (Ask, [27298, 0]), 3325.3999),
         "ask[-1,0]  = 3325.3999  (last chunk row, trimmed)");
      Check
        (Near (Element_At (Ask, [12345, 77]), 77.0),
         "ask[12345,77] = 77.0  (interior chunk 3.2)");
      Check (Near (Element_At (Iv, [100, 50]), 0.14845727), "iv[100,50]");
      Check (Near (Element_At (Dl, [100, 50]), 0.98302108), "delta[100,50]");
   end;
   New_Line;

   if Failures = 0 then
      Put_Line ("ALL CHECKS PASSED");
   else
      Put_Line (Failures'Image & " CHECK(S) FAILED");
      Set_Exit_Status (Failure);
   end if;
end Read_Spxw;
