package body Zarr.Fills is

   Pos_Inf : constant Float := To_Float (16#7F80_0000#);
   Neg_Inf : constant Float := To_Float (16#FF80_0000#);

   function Float_Fill (Token : String; Default : Float) return Float is
   begin
      if Token = "" or else Token = "null" then
         return Default;
      elsif Token = "NaN" then
         return Quiet_NaN;
      elsif Token = "Infinity" then
         return Pos_Inf;
      elsif Token = "-Infinity" then
         return Neg_Inf;
      else
         return Float'Value (Token);
      end if;
   exception
      when others =>
         return Default;
   end Float_Fill;

   function I32_Fill
     (Token : String; Default : Interfaces.Integer_32)
      return Interfaces.Integer_32 is
   begin
      if Token = "" or else Token = "null" then
         return Default;
      end if;
      return Interfaces.Integer_32'Value (Token);
   exception
      when others =>
         return Default;
   end I32_Fill;

   function I64_Fill
     (Token : String; Default : Interfaces.Integer_64)
      return Interfaces.Integer_64 is
   begin
      if Token = "" or else Token = "null" then
         return Default;
      end if;
      return Interfaces.Integer_64'Value (Token);
   exception
      when others =>
         return Default;
   end I64_Fill;

end Zarr.Fills;
