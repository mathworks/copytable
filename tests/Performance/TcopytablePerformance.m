classdef TcopytablePerformance < matlab.perftest.TestCase

    properties
        inputSingleTable
        inputMultipleTable
    end

    methods (Test)
        function testSingleColumn(testCase)
            copytable(testCase.inputSingleTable)
        end

        function testMultipleColumns(testCase)
            copytable(testCase.inputMultipleTable)
        end
    end

    methods (TestClassSetup)

        function classSetup1(testCase)
            % Set up shared state for all tests.
            n = 100000;
            data = rand(n,1);
            T = table(data);
            testCase.inputSingleTable = T;

            n2 = floor(sqrt(n));
            data2 = rand(n2);
            T2 = array2table(data2);
            testCase.inputMultipleTable = T2;
            % Tear down with testCase.addTeardown.
        end

    end
end