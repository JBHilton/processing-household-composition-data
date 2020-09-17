function [ct1088] = load_CT1088()

% This loads the csv files generated in combine_CT1088_tables into a single
% table called CT1088

addpath data;


listing=dir('data/CT1088_tables');
[ht,~]=size(listing);
filenames={};
for i=1:ht
    filenames{i}=['data/CT1088_tables/' listing(i).name];
end
filenames = filenames((contains(filenames,'CT1088')));
filenames = filenames((contains(filenames,'.csv')));
no_files = length(filenames);

ct1088=[];
for i=1:no_files
    ct1088 = [ct1088; readtable(filenames{i})];
end

ct1088.Properties.VariableNames = {'COUNTRY','LA','MSOA','LSOA','OA',...
    'a0_9','a10_19','a20_29','a30_39','a40_49','a50_59','a60_69','a70_79',...
    'a_80','count'};

clear('listing','ht','filenames','no_files','i');

end