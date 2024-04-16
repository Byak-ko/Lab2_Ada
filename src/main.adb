with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;

procedure Main is

    min_val : Integer;
    min_idx : Integer;

   dim : constant integer := 500000;
   thread_num : constant integer := 3;

   arr : array(1..dim) of integer;
   subtype Random_Range is Integer range 1 .. Dim;

   package R is new
     Ada.Numerics.Discrete_Random (Random_Range);
   use R;

   procedure Init_Arr is
      G : Generator;
      R : Random_Range;
   begin
      Reset (G);

      for I in 1..Dim loop
         R := Random(G);
         Arr(I) := R;
      end loop;

      Arr(Random(G)) := -1;
   end Init_Arr;

   function part_min(start_index, finish_index : in integer) return integer is
      min_val : integer := Integer'Last;
      min_index : integer;
   begin
      for i in start_index..finish_index loop
         if arr(i) < min_val then
            min_val := arr(i);
            min_index := i;
         end if;
      end loop;
      return min_index;
   end part_min;

   protected part_manager is
      procedure set_part_min(min : in Integer; index : in Integer);
      entry get_min(min : out Integer; index : out Integer);
   private
      tasks_count : Integer := 0;
      min1 : Integer := Integer'Last;
      min_index : Integer;
   end part_manager;

   protected body part_manager is
      procedure set_part_min(min : in Integer; index : in Integer) is
      begin
         if min1 > min then
            min1 := min;
            min_index := index;
         end if;
         tasks_count := tasks_count + 1;
      end set_part_min;

      entry get_min(min : out Integer; index : out Integer) when tasks_count = thread_num is
      begin
         min := min1;
         index := min_index;
      end get_min;
   end part_manager;

   task type starter_thread is
      entry start(start_index, finish_index : in Integer);
   end starter_thread;

   task body starter_thread is
      min_val : Integer := Integer'Last;
      min_index : Integer;
      start_index, finish_index : Integer;
   begin
      accept start(start_index, finish_index : in Integer) do
         starter_thread.start_index := start_index;
         starter_thread.finish_index := finish_index;
      end start;
      min_index := part_min(start_index  => start_index,
                            finish_index => finish_index);
      min_val := arr(min_index);
      part_manager.set_part_min(min_val, min_index);
   end starter_thread;

   procedure parallel_min(min_value : out Integer; min_index : out Integer) is
      min : Integer := Integer'Last;
      index : Integer;
      thread : array(1..thread_num) of starter_thread;
      step : Integer := dim / thread_num;
      start_index, finish_index : Integer := 1;
   begin
      for i in 1..thread_num loop
         if i = thread_num then
            finish_index := dim;
         else
            finish_index := start_index + step - 1;
         end if;
         thread(i).start(start_index, finish_index);
         start_index := finish_index + 1;
      end loop;

      part_manager.get_min(min, index);
      min_value := min;
      min_index := index;
   end parallel_min;


begin
   Init_Arr;

   begin
      parallel_min(min_val, min_idx);
      Put_Line("Index of Min value: " & min_idx'Img);
      Put_Line("Min value: " & min_val'Img);
   end;
end Main;
