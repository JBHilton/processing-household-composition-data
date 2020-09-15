% In this example we use the ONS ten year age band household composition
% data to construct a single histogram defining the household compositions
% of 95% of England and Wales' populations using a simple division into
% adults (20 and over) and children (19 and under).

addpath functions;

% Load composition data
ct1088 = load_CT1088();
ct1089 = readtable('data/CT1089.xlsx');

% Merge age classes in CT1088 to get 0-19 and 20+ classes:
ct1088_ind = [1 1 2 2 2 2 2 2 2]; % This specifies which new age class each old class maps to
ct1088_merger = sparse(1:9,ct1088_ind,1); % This encodes the mapping as a matrix
ct1088_numstart = find(varfun(@isnumeric,ct1088,'OutputFormat','uniform'),1); % This is column where composition data starts
merged_ct1088_data = [ct1088(:,1:ct1088_numstart-1)... We multiply the compositions by the merger matrix to convert to two-age-class compositions
    array2table(table2array(ct1088(:,ct1088_numstart:end-1))*ct1088_merger)...
    ct1088(:,end)];

% Merge age classes in CT1089 to get 0-19 and 20+ classes:
ct1089_ind = [1 2 2]; % CT1089 only has three age classes
ct1089_merger = sparse(1:3,ct1089_ind,1);
ct1089_numstart = find(varfun(@isnumeric,ct1089,'OutputFormat','uniform'),1);
merged_ct1089_data = [ct1089(:,1:ct1089_numstart-1)...
    array2table(table2array(ct1089(:,ct1089_numstart:end-1))*ct1089_merger)...
    ct1089(:,end)];

merged_hh_data = [merged_ct1088_data; merged_ct1089_data]; % Combine merged data into a single table

p = 5e-2; % We will remove the top 5% of the population by household size
filtered_hh_data = filter_rare_households_ONS(merged_hh_data,p);

% Now construct the England and Wales level histogram:
[composition_list,composition_dist] = build_hh_dist_from_ONS_data(filtered_hh_data,'ALL');

% We can also check how big an age-and-household-structured epidemic model
% with a given number of compartments will be (this is useful for deciding
% computational requirements for a model using the household data):
disp(['With three epidemic compartments, system size will be ',...
    num2str(calculate_system_size(table2array(composition_list),3)), '.']);
disp(['With four epidemic compartments, system size will be ',...
    num2str(calculate_system_size(table2array(composition_list),4)), '.']);
disp(['With five epidemic compartments, system size will be ',...
    num2str(calculate_system_size(table2array(composition_list),5)), '.']);
disp(['With six epidemic compartments, system size will be ',...
    num2str(calculate_system_size(table2array(composition_list),6)), '.']);