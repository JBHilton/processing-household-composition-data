% This script creates a complete CT1088 dataset combining the regional
% subtables from the ONS website. Run download_CT1088_CT1089.m before
% running this script to download the appropriate files.

addpath data;


disp('Finding dataset filenames.')
listing=dir('data/CT1088_tables');
[ht,~]=size(listing);
filenames={};
for i=1:ht
    filenames{i}=['data/CT1088_tables/' listing(i).name];
end
filenames = filenames((contains(filenames,'CT1088')));
filenames = filenames((contains(filenames,'.xlsx')));
no_files = length(filenames);

if isfile('data/sheet_details.mat')
    load('data/sheet_details.mat');
else
    disp('Calculating number of sheets in each dataset.');
    sheets=cell(no_files);
    no_sheets=zeros(no_files,1);
    tic
    for i=1:no_files
        [~,sheets{i}] = xlsfinfo(filenames{i});
        no_sheets(i) = length(sheets{i});
        elapsed = toc;
        disp([num2str(elapsed) ' seconds elapsed, estimated '...
            num2str((elapsed)*(no_files-i)/i) ' remaining.']);
    end
    cum_sheet_nos = cumsum(no_sheets);
    total_sheets = cum_sheet_nos(end);
    save('data/sheet_details.mat','sheets','no_sheets','cum_sheet_nos','total_sheets');
end

disp('Reading tables from data files.')
e=actxserver('Excel.Application');
tic
for i=1:no_files
    
    new_filename = [filenames{i}(1:end-4) 'csv'];
    
    this_table = [];
    
    ExcelWorkbook = e.workbooks.Open([cd(pwd) '/' filenames{i}]);
    for j=2:no_sheets(i)
        Sheet=ExcelWorkbook.Sheets.Item(j);
        Range=Sheet.UsedRange;
        r = (Range.Value(2:end,1:end-1));
        LA = char(r(:,2));
        r(:,2) = cellstr(LA(:,1:9));
        this_table = [this_table; r];
    end
    ExcelWorkbook.Close;
    
    writecell(this_table, new_filename);
    delete(filenames{i});
    
    elapsed = toc;
    disp([num2str(i) ' of ' num2str(no_files)...
        ' spreadsheets read in ' num2str((elapsed)/60)...
        ' minutes, estimated ' num2str((1/60)*(elapsed)*...
        (total_sheets-cum_sheet_nos(i))/cum_sheet_nos(i))...
        ' minutes remaining.'])
end

e.Quit;
e.delete;

ct1089 = readtable('data/CT1089.xlsx','Sheet','CT1089');
ct1089 = ct1089(:,1:9);
ct1089.Properties.VariableNames{9}='count';
writetable(ct1089,'data/CT1089.csv');
delete('data/CT1089.xlsx');