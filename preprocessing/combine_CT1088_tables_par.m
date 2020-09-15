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

new_filenames={};
for i=1:no_files
   new_filenames{i} = [filenames{i}(20:end-4) 'csv']; 
end

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
tic
parfor(i=1:no_files,4)
    
    this_table = [];
    e=actxserver('Excel.Application');
    ExcelWorkbook = e.workbooks.Open([cd(pwd) '/' filenames{i}]);
    for j=2:no_sheets(i)
        Sheet=ExcelWorkbook.Sheets.Item(j);
        Range=Sheet.UsedRange;
        r=cell2table(Range.Value);
        this_table = [this_table; r(2:end,1:end-1)];
    end
    ExcelWorkbook.Close;
    e.Quit;
    e.delete;
    
    writetable(this_table, ['data/CT1088_tables/' new_filenames{i}], 'WriteVariableNames', 0);
    
    dir_now = dir('data/CT1088_tables');
    
    delete(filenames{i});
end
toc