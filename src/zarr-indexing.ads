--  The provable arithmetic core: chunk-grid sizing and row-major linearising,
--  for arbitrary rank.  Products and offsets are computed in Long_Long_Integer
--  and *saturate* at Overflow_Sentinel, so they provably cannot overflow no
--  matter the rank; a result equal to the sentinel means the value does not
--  fit a Natural (array too large to materialise) and the caller raises.
--  Fully analysed by SPARK -- no rank cap is needed for the proofs.

package Zarr.Indexing
  with SPARK_Mode
is

   --  One past the largest representable element count or linear index.
   Overflow_Sentinel : constant Long_Long_Integer :=
     Long_Long_Integer (Natural'Last) + 1;

   function Ceil_Div (A, B : Positive) return Positive
   with Pre => A <= Integer'Last - B, Post => Ceil_Div'Result >= 1;

   --  Element count = product of the extents, saturating at Overflow_Sentinel.
   function Product (E : Extent_Array) return Long_Long_Integer
   with
     Pre  => (for all I in E'Range => E (I) >= 1),
     Post => Product'Result >= 1 and then Product'Result <= Overflow_Sentinel;

   --  Row-major (C order) linear offset of Coord within Shape (0-based),
   --  saturating at Overflow_Sentinel.
   function Linear (Coord, Shape : Extent_Array) return Long_Long_Integer
   with
     Pre  =>
       Coord'First = Shape'First
       and then Coord'Last = Shape'Last
       and then (for all I in Coord'Range => Coord (I) < Shape (I)),
     Post => Linear'Result >= 0 and then Linear'Result <= Overflow_Sentinel;

end Zarr.Indexing;
