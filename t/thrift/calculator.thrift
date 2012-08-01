namespace perl Services

typedef i32 MyInteger

// A single calculator operation
enum Operation {
  ADD = 1,
  SUBTRACT = 2,
  MULTIPLY = 3,
  DIVIDE = 4
}

// A piece of work to perform
struct Work {
  1: MyInteger num1 = 0,
  2: i32 num2,
  3: Operation op,
  4: optional string comment,
}

// Simple invalid operation
exception InvalidOperation {
  1: i32 what,
  2: string why
}

/*
	The Calculator service
	@role public
*/
service Calculator {
	/*
		Add two numbers together
	*/
   i32 add(1:i32 num1, 2:i32 num2),

	/*
		Perform a single operation
	*/
   i32 calculate(1:i32 logid, 2:Work w) throws (1:InvalidOperation ouch),
}
