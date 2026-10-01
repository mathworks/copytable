function copytable(inputTable,inputDelimiter,includeHeaders)
%COPYTABLE Copy a table, timetable, eventtable, or uitable to the system
%clipboard as delimited text.
%
%   COPYTABLE(INPUTTABLE) copies the contents of INPUTTABLE to the system
%   clipboard using the default delimiter "," and includes column headers
%   when available.
%
%   Syntax
%   ------
%   COPYTABLE(INPUTTABLE)
%   COPYTABLE(INPUTTABLE, INPUTDELIMITER)
%   COPYTABLE(INPUTTABLE, INPUTDELIMITER, INCLUDEHEADERS)
%
%   COPYTABLE(INPUTTABLE, INPUTDELIMITER) uses INPUTDELIMITER as the field
%   separator. INPUTDELIMITER may be any text scalar such as:
%       ","    Comma-separated values (CSV)
%       "\t"   Tab-separated values (TSV)
%       ";"    Semicolon-separated values
%       "|"    Pipe-delimited values
%
%   The default delimiter is ",".
%
%   COPYTABLE(INPUTTABLE, INPUTDELIMITER, INCLUDEHEADERS) controls whether
%   column headers are included in the clipboard output. INCLUDEHEADERS is
%   a logical scalar. The default is true.
%
%   INPUTTABLE can be a:
%       table, 
%       timetable, 
%       eventtable, 
%       matlab.ui.control.Table (uitable)
%
%   Supported scalar data types include:
%       double
%       single
%       half
%       integer types
%       logical
%       string
%       char
%       datetime
%       duration
%       calendarDuration
%       categorical
%       complex numeric values
%
%   Behavior
%   --------
%
%   - For table, timetable, and eventtable inputs, column names are taken
%     from the table object.
%
%   - For uitable inputs, column names are taken from the ColumnName
%     property. If ColumnName is empty, no header row is generated.
%
%   - INCLUDEHEADERS=true (default) includes column headers when
%     available. INCLUDEHEADERS=false omits the header row.
%
%   - Numeric values are exported using a precision appropriate for their
%     underlying numeric type.
%
%   - Missing values and empty entries are exported as empty fields.
%
%   - Fields containing a comma, quotation marks, newlines, or carriage
%     returns are escaped automatically. Quotation marks are doubled and
%     fields are wrapped in double quotes when required.
%
%   Limitations
%   -----------
%
%   - Each table entry must contain a scalar value.
%
%   - Vector-valued entries, matrix-valued entries, multidimensional
%     arrays, structures, dictionaries, and other non-scalar container
%     objects are not supported.
%
%   - Nested table-like containers are not supported.
%
%   See also TABLE, TIMETABLE, UITABLE, CLIPBOARD.
%
%   Copyright 2026 The MathWorks, Inc®.

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
delete(fig)

Example 4: 
fig = uifigure;
r = rand(10,3);
r(1) = r(1)/1e10;
r = single(r);
uit = uitable(fig,"Data",r);
copytable(uit,"\t")
delete(fig)

Example 5:
fig = uifigure;
uit = uitable(fig,"Data",string(randi(100,10,3)));
copytable(uit,"|")
delete(fig)

Example 6:
MeasurementTime = datetime(["2015-12-18 08:03:05";"2015-12-18 10:03:17";"2015-12-18 12:03:13"]);
Temp = [37.3;39.1;42.3];
Pressure = [30.1;30.03;29.9];
WindSpeed = [13.4;6.5;7.3];
TT = timetable(MeasurementTime,Temp,Pressure,WindSpeed)
copytable(TT,",",false)

%}

arguments (Input)
    inputTable {mustBeA(inputTable, {'table','matlab.ui.control.Table','timetable','eventtable'}),mustBeNonempty}
    inputDelimiter {mustBeTextScalar} = ","
    includeHeaders (1,1) {mustBeA(includeHeaders,'logical')} = true
end

%this logic changes string literals to escape characters if required
delimiter = updateDelimieter(inputDelimiter);

%convert all inputs to a table for uniformity
[normalizedTable,hasColumnNames] = convertInputToTable(inputTable);

%need to check whether user initially had empty ColumnName. this happens only in a uitable
if hasColumnNames
    tableColumnNames = string(normalizedTable.Properties.VariableNames);
else 
    %only an empty uitable's ColumnName should reach this
    tableColumnNames = [];
end

%convert character array to string array if present. then get variable types 
% which are only available in tables
normalizedTable = convertCharacterArrayToStringArray(...
    normalizedTable,normalizedTable.Properties.VariableTypes);
variableTypes = normalizedTable.Properties.VariableTypes;

%check for non scalar variables. this cannot happen in uitables
isTableVariableScalar = varfun(@isscalar,normalizedTable(1,:),'OutputFormat','uniform');
isTableVariableNotScalar = ~isTableVariableScalar;
if any(isTableVariableNotScalar)
    [~, badCol] = find(isTableVariableNotScalar, 1, 'first'); %just get the first instance
    error('copytable:InvalidTableSize', 'Table variable %s is not scalar',...
        tableColumnNames(badCol))
end

%loop over columns and create string array of contents
numberOfColumns = width(normalizedTable);
numberOfRows = height(normalizedTable);
textData = strings(numberOfRows,numberOfColumns);
for column = 1:numberOfColumns
    data = normalizedTable{:,column};
    columnType = variableTypes(column);
    columnString = convertColumnToString(data,columnType);
    textData(:,column) = columnString;
end

%build csv arrays, delimit with comma, and combine
columnNamesJoined = escapeCharactersBlock(tableColumnNames);
headerLine = join(columnNamesJoined, delimiter);

%put together data and replace missing with ""
dataJoined = escapeCharactersBlock(textData);
dataJoined(ismissing(dataJoined)) = "";
dataLines = join(dataJoined, delimiter, 2);

%build the table as string data
if includeHeaders && hasColumnNames
    tableData = [headerLine; dataLines];
else
    tableData = dataLines;
end
tableAsString = join(tableData, newline);

clipboard('copy', tableAsString)

end

%% helper functions

function headerNames = getUITableColumnName(uit)
uitcolumnname = uit.ColumnName;
n = size(uit.Data,2);
if isempty(uitcolumnname)
    headerNames = [];
elseif ischar(uitcolumnname) && strcmpi(uitcolumnname,'numbered')
    headerNames = string(1:n);
else
    headerNames = string(uitcolumnname(:));
    headerNamesSize = numel(headerNames);
    if headerNamesSize > n
        %if user puts in too many values to ColumnName
        headerNames = headerNames(1:n);
    elseif headerNamesSize < n
        %if user doesn't put enough values in ColumnName, give default name
        extraVariableNames = "Var" + string(1:n - headerNamesSize)';
        headerNames = [headerNames;extraVariableNames];
    end
end
end

function tf = isNonScalarTableEntry(x)

if isempty(x)
    tf = false; %just treat empty as scalar
elseif isnumeric(x) || islogical(x)
    tf = ~isscalar(x);
elseif isstring(x)
    tf = ~isscalar(x);
elseif isdatetime(x) || isduration(x) || iscalendarduration(x)
    tf = ~isscalar(x);
elseif iscategorical(x)
    tf = ~isscalar(x);
elseif ischar(x)
    tf = false; % char row vector is treated as one text value
elseif isstruct(x)
    tf = true;
elseif isa(x,'dictionary')
    tf = true;
elseif isobject(x)
    %catch all for objects
    tf = true;
else
    %probably shouldn't reach this condition, but put it here anyway
    tf = ~isscalar(x);
end

end

function s = convertValueToString(x)

if isnumeric(x)
    if isempty(x)
        s = "";
    elseif isa(x,'double')
        s = string(sprintf('%.16g', x));
    elseif isa(x,'single')
        s = string(sprintf('%.8g', x));
    else
        s = string(mat2str(x));
    end
elseif isempty(x) || any(ismissing(x))
    s = "";
elseif islogical(x)
    s = string(mat2str(x));
elseif isstring(x)
    s = x;
elseif ischar(x)
    s = string(x);
elseif isdatetime(x) || isduration(x) || iscalendarduration(x)
    s = string(x);
elseif iscategorical(x)
    s = string(x);
elseif isa(x,'function_handle')
    s = string(func2str(x));
else
    s = string(x);
end

end

function s = escapeCharactersBlock(s)

s = string(s);

needsQuotesIndex = ...
    contains(s, ",") | ...
    contains(s, '"') | ...
    contains(s, newline) |...
    contains(s, sprintf('\r'));
%maybe add | contains(s,delimiter) here, but this would be an edge case

s = replace(s, '"', '""');
s(needsQuotesIndex) = '"' + s(needsQuotesIndex) + '"';

end

function s = convertColumnToString(x,varType)

switch varType
    case 'missing'
        s = "";
    case 'double'
        fmt = "%.16g";
        isComplexNumber = ~isreal(x);
        if isComplexNumber
            s = composeComplex(fmt,x);
            s = strrep(s,"+0i","");
        else
            s = compose(fmt,x);
        end
    case 'single'
        fmt = "%.8g";
        isComplexNumber = ~isreal(x);
        if isComplexNumber
            s = composeComplex(fmt,x);
            s = strrep(s,"+0i","");
        else
            s = compose(fmt,x);
        end
    case 'half'
        fmt = "%.5g";
        isComplexNumber = ~isreal(x);
        if isComplexNumber
            s = composeComplex(fmt,x);
            s = strrep(s,"+0i","");
        else
            s = compose(fmt,x);
        end
    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
        fmt = "%d";
        isComplexNumber = ~isreal(x);
        if isComplexNumber
            s = composeComplex(fmt,x);
            s = strrep(s,"+0i","");
        else
            s = compose(fmt,x);
        end
    case 'string'
        s = x;
    case {'datetime','duration','calendarDuration','logical','char','categorical'}
        s = string(x);
    case 'cell'
        %need to build them all individually
        isNestedCellArray = cell2mat(cellfun(@iscell, x, 'UniformOutput', false));
        stillContainsNestedCells = any(isNestedCellArray,"all");
        if stillContainsNestedCells
            [badCellRow, ~] = find(isNestedCellArray, 1, 'first'); %just get the first instance of a bad cell
            error('copytable:InvalidTableStructure',...
                'Input table contains multiple nested cells in row %d.',...
                badCellRow);

        end

        isBadCell = cellfun(@isNonScalarTableEntry, x);
        isBadCellFlattened = isBadCell(:);
        if any(isBadCellFlattened)
            [badRow, ~] = find(isBadCell, 1, 'first'); %just get the first instance of a bad cell
            error('copytable:InvalidTableSize', 'Contents of cell in row %d are not scalar',...
                badRow)
        end

        %after all the checks, convert the cell to string
        s = cellfun(@convertValueToString, x);

    case 'struct'
        error('copytable:InvalidTableInput', 'Table contains a struct data type.')
    otherwise
        try
            s = string(x);
        catch ME
            error('copytable:InvalidTableInput','Table contains a %s data type which is unsupported.',...
                class(x))
        end
end


end

function s = composeComplex(fmt,x)

sr = compose(fmt,real(x));
si = compose(fmt,imag(x));

isNegativeImag = imag(x) < 0;

s = sr + "+" + si + "i";
s(isNegativeImag) = sr(isNegativeImag) + si(isNegativeImag) + "i";

end

function updatedDelimiter = updateDelimieter(originalDelimiter)
if originalDelimiter == "\t"
    % make this tab delimiter if user enters '\t'.
    updatedDelimiter = char(9);
elseif originalDelimiter == "\r"
    % make this carriage return if user enters '\r'.
    updatedDelimiter = char(13);
elseif originalDelimiter == "\n"
    updatedDelimiter = newline;
else
    updatedDelimiter = originalDelimiter;
end
end

function updatedTable = convertCharacterArrayToStringArray(oldTable,variableTypes)
updatedTable = oldTable;
n = numel(variableTypes);
for ii = 1:n
    columnDataType = variableTypes(ii);
    if columnDataType == "char"
        columnName = updatedTable.Properties.VariableNames{ii};
        updatedTable.(columnName) = string(updatedTable.(columnName));
    end
end
end

function [convertedTable,hasColumnNames] = convertInputToTable(originalTableObj)
hasColumnNames = true; %this is the case for all tables except potentially uitable
switch class(originalTableObj)
    case 'matlab.ui.control.Table'
        tableColumnNames = getUITableColumnName(originalTableObj);
        hasColumnNames = ~isempty(tableColumnNames);
        rawData = originalTableObj.Data;

        if istable(rawData)
            convertedTable = rawData;
        elseif iscell(rawData)
            convertedTable = cell2table(rawData);
        else
            convertedTable = array2table(rawData);
        end

        if hasColumnNames
            convertedTable.Properties.VariableNames = tableColumnNames;
        end
    case 'eventtable'
        convertedTable = timetable2table(originalTableObj);
    case 'timetable'
        convertedTable = timetable2table(originalTableObj);
    case'table'
        convertedTable = originalTableObj;
end
end
