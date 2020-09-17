% This script builds the UK composition list and distribution according to
% a child-adult <20 >=20 age split, as used in the external isolation
% study.

ind = [1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2];
merger = sparse(1:17,ind,1);

hh_data=readtable('data/five_year_age_data.csv');
merged_hh_data = [hh_data(:,1:4) array2table(table2array(hh_data(:,5:21))*merger) hh_data(:,end)];

cutoff_list = 5e-2;

filtered_hh_data = filter_rare_households_uk(merged_hh_data,cutoff_list);
[composition_list,composition_dist] = build_uk_hh_dist_from_ONS_data(filtered_hh_data,'ALL');
composition_list.Properties.VariableNames = {'Children','Adults'};
system_size = calculate_system_size(table2array(composition_list),6);

disp(['With six compartments, system size will be ', num2str(system_size), '.']);

writetable(composition_list,'data/eng_and_wales_adult_child_composition_list.csv');
writetable(composition_dist,'data/eng_and_wales_adult_child_composition_dist.csv');