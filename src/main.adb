with Ada.Text_IO; use Ada.Text_IO;

procedure Main is

   dim : constant integer := 100000;
   thread_num : constant integer := 3;

   arr : array(1..dim) of integer;

   procedure Init_Arr is
   begin
      for i in 1..dim loop
         arr(i) := i;
      end loop;
      arr(42345) := -1;
   end Init_Arr;


  -- ======================================================== --

   function part_min(start_index, finish_index : in integer) return integer is
      min_val : integer := Integer'Last;
   begin
      for i in start_index..finish_index loop
         if arr(i) < min_val then
            min_val := arr(i);
         end if;
      end loop;
      --  Put_Line(min_val'img);
      return min_val;
   end part_min;


     -- ======================================================== --


   protected part_manager is
      procedure set_part_min(min : in Integer);
      entry get_min(min : out Integer);
   private
      tasks_count : Integer := 0;
      min1 : Integer := Integer'Last;
   end part_manager;

   protected body part_manager is
      procedure set_part_min(min : in Integer) is
      begin
         if min < min1 then
            min1 := min;
         end if;
         tasks_count := tasks_count + 1;
      end set_part_min;

      entry get_min(min : out Integer) when tasks_count = thread_num is
      begin
         min := min1;
      end get_min;

   end part_manager;


     -- ======================================================== --


   task type starter_thread is
      entry start(start_index, finish_index : in Integer);
   end starter_thread;

   task body starter_thread is
      min_val : Integer := Integer'Last;
      start_index, finish_index : Integer;
   begin
      accept start(start_index, finish_index : in Integer) do
         starter_thread.start_index := start_index;
         starter_thread.finish_index := finish_index;
      end start;
      min_val := part_min(start_index  => start_index,
                          finish_index => finish_index);
      part_manager.set_part_min(min_val);
   end starter_thread;


     -- ======================================================== --

   function parallel_min return Integer is
      min : Integer := Integer'Last;
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

      part_manager.get_min(min);
   return min;
   end parallel_min;


     -- ======================================================== --


begin
   Init_Arr;
   --  Put_Line(part_min(1, dim)'img);
   Put_Line("Min value: " & parallel_min'img);
end Main;
