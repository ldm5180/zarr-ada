with Ada.Directories;
with Ada.Streams.Stream_IO;

package body Zarr.Stores is

   use type Ada.Directories.File_Kind;

   function Exists (Path : String) return Boolean
   is (Ada.Directories.Exists (Path)
       and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File);

   function Read_File (Path : String) return Byte_Array is
      use Ada.Streams;
      use Ada.Streams.Stream_IO;
      F   : File_Type;
      Len : Natural;
   begin
      Open (F, In_File, Path);
      Len := Natural (Size (F));
      declare
         SEA    : Stream_Element_Array (1 .. Stream_Element_Offset (Len));
         Last   : Stream_Element_Offset;
         Result : Byte_Array (0 .. Len - 1);
      begin
         if Len > 0 then
            Read (F, SEA, Last);
            for I in Result'Range loop
               Result (I) := Byte (SEA (Stream_Element_Offset (I + 1)));
            end loop;
         end if;
         Close (F);
         return Result;
      end;
   exception
      when IO_Error =>
         raise;
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (F) then
            Ada.Streams.Stream_IO.Close (F);
         end if;
         raise IO_Error with "cannot read " & Path;
   end Read_File;

   function Read_Text (Path : String) return String is
      B : constant Byte_Array := Read_File (Path);
      S : String (1 .. B'Length);
   begin
      for I in S'Range loop
         S (I) := Character'Val (Natural (B (B'First + (I - 1))));
      end loop;
      return S;
   end Read_Text;

end Zarr.Stores;
