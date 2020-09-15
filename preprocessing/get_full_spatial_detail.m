% This script appends lower levels of spatial encoding up to country code
% to the 5-year age band household composition data gathered during the
% 2011 census and available on request from the UK data service. The data
% is at the level of Lower Layer Super Output Areas (LSOAs), but does not
% specify the coarser output areas in which these lower layer super output
% areas are contained. While the source data is split into two datasets
% containing households of size 6 and lower and 7 and higher respectively,
% the table full_spatial_table contains both sets of households. This table
% contains all the size 6 and lower households then all the size 7 and
% higher households, meaning each LSOA's households will be split across
% the two sections of the table.

disp('Loading 10 year age band composition data and reading output area codes.');
CT1088 = readtable('data/CT1088.csv');
spatial_table = unique(CT1088(:,1:4),'rows','stable');
clear CT1088;
LSOA_short_list = spatial_table.LSOA_CODE;
no_rows = length(LSOA_short_list);
country_list = spatial_table.COUNTRY_CODE;
wales_start = find(strcmp(country_list,country_list(end)),1);

spatial_numerical = zeros(no_rows,4);
disp('Assigning integer values to output area codes.');
for i=1:wales_start-1
    for j=1:4
        spatial_numerical(i,j) = -str2num(spatial_table{i,j}{:}(2:end));
    end
    if rem(i,2500)==0
        disp(['Completed ' num2str(4*i) ' of ' num2str(4*no_rows) ' assignments.']);
    end
end
for i=wales_start:no_rows
    for j=1:4
        spatial_numerical(i,j) = str2num(spatial_table{i,j}{:}(2:end));
    end
    if rem(i,2500)==0
        disp(['Completed ' num2str(4*i) ' of ' num2str(4*no_rows) ' assignments.']);
    end
end

LSOA_short_numeric = spatial_numerical(:,4);

clear country_list;

disp('Reading 5 year age band data for households size <=6.')
hh_data=readtable('data/5yr_6_or_smaller.csv');
LSOA_long_list = hh_data.LSOA_CODE;
no_rows = length(LSOA_long_list);
wales_start_long = find(strcmp(LSOA_long_list,spatial_table{wales_start,4}{:}),1);
disp('Assigning integer values to LSOA area codes from 5 year age band data for households size <=6.');
LSOA_long_numeric = zeros(length(LSOA_long_list),1);
for i=1:no_rows
    if strcmp(LSOA_long_list{i}(1),'E')
        LSOA_long_numeric(i) = -str2num(LSOA_long_list{i}(2:end));
    else
        LSOA_long_numeric(i) = str2num(LSOA_long_list{i}(2:end));
    end
    if rem(i,100000)==0
        disp(['Completed ' num2str(i) ' of ' num2str(no_rows) ' assignments.']);
    end
end
disp('Appending additional spatial columns to 5 year age band data for households size <=6.');
start_time = cputime;
long_spatial_table = cell(no_rows,3);
short_length = length(LSOA_short_numeric);
for i=1:short_length
    loc = find(LSOA_long_numeric==LSOA_short_numeric(i));
    long_spatial_table(loc,:) = repelem(spatial_table{i,1:3},length(loc),1);
    if rem(i,10000)==0
        disp([num2str(cputime-start_time) ' elapsed, estimated ' num2str((short_length-i)*(cputime-start_time)/i) ' remaining.']);
    end
end
extra_spatial_columns = cell2table(long_spatial_table);
extra_spatial_columns.Properties.VariableNames=spatial_table.Properties.VariableNames(1:3);
full_spatial_table = [extra_spatial_columns hh_data];

disp('Reading 5 year age band data for households size >=7.')
hh_data=readtable('data/5yr_7_or_larger.csv');
LSOA_long_list = hh_data.LSOA_CODE;
no_rows = length(LSOA_long_list);
wales_start_long = find(strcmp(LSOA_long_list,spatial_table{wales_start,4}{:}),1);
disp('Assigning integer values to LSOA area codes from 5 year age band data for households size >=7.');
LSOA_long_numeric = zeros(length(LSOA_long_list),1);
for i=1:no_rows
    if strcmp(LSOA_long_list{i}(1),'E')
        LSOA_long_numeric(i) = -str2num(LSOA_long_list{i}(2:end));
    else
        LSOA_long_numeric(i) = str2num(LSOA_long_list{i}(2:end));
    end
    if rem(i,100000)==0
        disp(['Completed ' num2str(i) ' of ' num2str(no_rows) ' assignments.']);
    end
end
disp('Appending additional spatial columns to 5 year age band data for households size >=7.');
start_time = cputime;
long_spatial_table = cell(no_rows,3);
short_length = length(LSOA_short_numeric);
for i=1:short_length
    loc = find(LSOA_long_numeric==LSOA_short_numeric(i));
    long_spatial_table(loc,:) = repelem(spatial_table{i,1:3},length(loc),1);
    if rem(i,10000)==0
        disp([num2str(cputime-start_time) ' elapsed, estimated ' num2str((short_length-i)*(cputime-start_time)/i) ' remaining.']);
    end
end
extra_spatial_columns = cell2table(long_spatial_table);
extra_spatial_columns.Properties.VariableNames=spatial_table.Properties.VariableNames(1:3);
full_spatial_table = [full_spatial_table; extra_spatial_columns hh_data];