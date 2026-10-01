function copytable_old(inputTable)
%copytable.m allows you to copy the data from a table into excel as a csv
%array

%inputTable can either be uitable or table

%{
Example 1: 
LastName = ["Sanchez";"Johnson";"Li";"Diaz";"Brown"];
Age = [38;43;38;40;49];
Smoker = logical([1;0;1;0;1]);
Height = [71;69;64;67;64];
Weight = [176;163;131;133;119];
T = table(LastName,Age,Smoker,Height,Weight);
copytable(T) %paste in Excel

Example 2:
LastName = ["Sanchez";"Johnson";"Li";"Diaz";"Brown"];
Age = [38;43;38;40;49];
Smoker = logical([1;0;1;0;1]);
Height = [71;69;64;67;64];
Weight = [176;163;131;133;119];
BloodPressure = [124 93; 109 77; 125 83; 117 75; 122 80];
T = table(LastName,Age,Smoker,Height,Weight,BloodPressure);
copytable(T) %this should error because BloodPressure is Nx2

Example 3:
dataCell = {'John', 25, 68.5; 'Sarah', 30, 72.0};
fig = uifigure;
uit = uitable(fig,'Data', dataCell, 'ColumnName', {'Name', 'Age', 'Weight'});
copytable(uit)

Example 4: 
fig = uifigure;
r = rand(10,3);
r(1) = r(1)/1e10;
uit = uitable(fig,"Data",r);
copytable(uit)

Example 5:
fig = uifigure;
uit = uitable(fig,"Data",string(randi(100,10,3)));
copytable(uit)

%}

arguments
    inputTable {mustBeA(inputTable, {'table','matlab.ui.control.Table'})}
end

%convert uitable to table if needed
if isa(inputTable,'matlab.ui.control.Table')
    uitableColumnNames = getUITableColumnName(inputTable);
    uitableData = cellstr(string(inputTable.Data));
    regularTable = cell2table(uitableData);
    regularTable.Properties.VariableNames = uitableColumnNames;
else
    regularTable = inputTable;
end

headerNames = string(regularTable.Properties.VariableNames);

%check whether each table variable is scalar (1x1 per row)
sizeCells = varfun(@size, regularTable, 'OutputFormat', 'cell');
sizeArray = reshape([sizeCells{:}],2,[]);
checkScalarIndices = sizeArray(2,:) > 1;
isNonScalarColumn = any(checkScalarIndices);
if isNonScalarColumn
    firstNonScalarColumn = find(checkScalarIndices,1,'first');
    errorID = 'copytable:InvalidTableSize';
    error(errorID,'Table variable %s is not scalar',char(headerNames(firstNonScalarColumn)))
end

%convert data in table to cell array
dataMatrix = cellstr(string(table2cell(regularTable)));

%combine headers and data rows with commas and stack them
headerLine = join(headerNames, ",");
dataLines = join(dataMatrix, ",");
combinedHeaderAndData = [headerLine; dataLines];

%stack them and join all rows with a newline character
finalString = join(combinedHeaderAndData, newline);

clipboard('copy', finalString)

end

function headerNames = getUITableColumnName(uit)
uitcolumnname = uit.ColumnName;
n = size(uit.Data,2);
if isempty(uitcolumnname)
    headerNames = string(1:n);
elseif ischar(uitcolumnname) && strcmpi(uitcolumnname,'numbered')
    headerNames = string(1:n);
else
    headerNames = string(uitcolumnname(:));
end
end