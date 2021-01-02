:- use_module(library(clpfd)).

:- include('utils.pl').

solve(RowsNumbers, ColumnsNumbers, Rows) :-
    % Domain and variables definition

    length(RowsNumbers, Size),           % Get size of square
    generate_grid(Rows, Size),           % Generate grid representing square
    generate_indexes(Indexes, Size),     % Generate grid representing square
    % print(Indexes), nl,

    % Constraints
    
    transpose(Rows, Columns),
    line_constraints(RowsNumbers, Rows),
    line_constraints(ColumnsNumbers, Columns),
    find_square(0, 0, Rows, Indexes, Size),

    % Solution search
    
    flatten(Rows, Vars),
    labeling([], Vars).

generate_grid(Grid, Size) :-
    generate_grid(Grid, Size, Size).

generate_grid([], _, 0).

generate_grid([GridRow|T], Size, Counter) :-
    C is Counter - 1,
    length(GridRow, Size),
    domain(GridRow, 0, 1),
    generate_grid(T, Size, C).

generate_indexes(Indexes, Size) :-
    generate_indexes(Indexes, 0, 0, Size).

generate_indexes([], I, _, Size) :-
    I == Size.

generate_indexes(Indexes, I, J, Size) :-
    J == Size,
    NewI is I + 1,
    generate_indexes(Indexes, NewI, 0, Size).

generate_indexes([[I, J]|T], I, J, Size) :-
    NewJ is J + 1,
    generate_indexes(T, I, NewJ, Size).

% Line constraints

line_constraints([], []).

line_constraints([FilledCells|T1], [GridLine|T2]) :-
    sum(GridLine, #=, FilledCells),
    line_constraints(T1, T2).

% Square constraints

find_square(Size, _, _, _, Size).

find_square(I, Size, _, Indexes,Size) :-        % Next row
    NewI is I + 1,  
    find_square(NewI, 0, _, Indexes, Size).

find_square(I, J, Rows, Indexes, Size) :-
    get_cell(I, J, Rows, Cell),                                      

    Cell #= 1 #<=> IsFilled,                   % If cell is filled  

    % Top cell

    TopI is I - 1,
    get_cell(TopI, J, Rows, TopCell),
    TopCell #= 0 #<=> IsTopBlank,
    
    % Left cell
    
    LeftJ is J - 1,
    get_cell(I, LeftJ, Rows, LeftCell),
    LeftCell #= 0 #<=> IsLeftBlank,

    % Upper left cell   
    
    get_cell(TopI, LeftJ, Rows, TopLeftCell),
    TopLeftCell #= 0 #<=> IsTopLeftBlank,

    (IsFilled #/\ IsTopBlank #/\ IsLeftBlank #/\ IsTopLeftBlank) #<=> IsSquare, % Is top left corner of a cell
    square_constraints(I, J, Rows, Indexes, IsSquare),

    NextJ is J + 1,
    
    find_square(I, NextJ, Rows, Indexes, Size).   

square_constraints(I, J, Rows, Indexes, IsSquare) :-
    square_lines_constraints(I, J, Rows, Indexes, IsSquare).

square_lines_constraints(I, J, Rows, Indexes, IsSquare) :-
    get_cell(BottomI, J, Rows, BottomCell),
    get_cell(I, RightJ, Rows, RightCell),

    BottomI - I #= Height,
    RightJ - J #= Width,
    SquareArea #= Height * Width,

    (
        foreach([IndexI, IndexJ], Indexes),
        foreach(FilledCell, FilledCells),
        param(I),
        param(BottomI),
        param(J),
        param(RightJ),
        param(Rows)
    do
        get_cell(IndexI, IndexJ, Rows, Cell),
        FilledCell #<=> (
            IndexI #>= I #/\
            IndexI #=< BottomI #/\
            IndexJ #>= J #/\
            IndexJ #=< RightJ #/\
            Cell #= 1
        )
    ),

    sum(FilledCells, #=, NumFilledCells),
    (
        (Height #= Width) #/\ (Height #>= 0) #/\ (Width #>= 0) #/\ 
        (BottomCell #= 1) #/\ (RightCell #= 1) #/\
        NumFilledCells #= SquareArea
    ) #<=> IsSquare.
