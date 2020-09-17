% In this example we use the ONS ten year age band household composition
% data and an estimate of the age-stratified proportion of people shielding
% to construct a single histogram defining the household compositions of
% 95% of England and Wales' populations using a simple division into adults
% (20 and over) and children (19 and under), with adults further divided
% into vulnerable individuals who have been instructed to shield and less
% vulnerable individuals who have not been instructed to shield. We start
% by constructing a household composition histogram according to the age
% classes used in the shielding data, then use the shielding data to
% divide the household types in this distribution according to how many
% vulnerable people are present, and finally merge the adult age classes in
% this distribution to get a three class child/non-vulnerable
% adult/vulnerable adult stratification. To simplify the code slightly, we
% will only use the household composition data for households of size six
% or less. This covers over 95% of the population of England and Wales and
% so we can expect it to give a reasonably accurate summary of the full
% population.

addpath functions;

% Load composition data
hh_data = load_CT1088();

sba = 0.01*[0,1.08,1.63,2.57,4.47,7.53,10.72,13.98]; % Shielding by age class - 0-20, 10 year bands up to 70, 70-75, 75+

% Merge age classes in data to match those in the shielding estimates
ind = [1 1 2 3 4 5 6 7 8 ]; % This specifies which new age class each old class maps to
merger = sparse(1:9,ind,1); % This encodes the mapping as a matrix
numstart = find(varfun(@isnumeric,hh_data,'OutputFormat','uniform'),1); % This is column where composition data starts
merged_hh_data = [hh_data(:,1:numstart-1)...
    array2table(table2array(hh_data(:,numstart:end-1))*merger)...
    hh_data(:,end)];
clear hh_data;

[composition_list,composition_dist] =... % This composition list is in terms of the age classes from the shielding data
    build_hh_dist_from_ONS_data(merged_hh_data,'ALL');

composition_dist = table2array(composition_dist);
composition_list = table2array(composition_list);
no_comps = length(composition_dist);

% We now reaggregate the compositions into a simple adult-child division.
% Note that we do not filter out the repeat compositions that will appear
% under this aggregation, so that line i of two_class_with_repeats is the
% two-age-class version of the i'th composition in composition_list.
reaggregator = [1 2 2 2 2 2 2 2];
reagg_matrix = sparse(1:8,reaggregator,1);
two_class_with_repeats = composition_list*reagg_matrix;

% In the following for loop, we work through each composition in
% composition_list and for each possible assignment of the adults present
% to the vulnerable class we add the resulting composition to
% new_comp_list, which is initially a copy of the two-age-class composition
% list with a column of zeros appended. The probability of each assignment
% of adults to the vulnerable class is calculated and appended to the
% composition distribution.
new_comp_list = [two_class_with_repeats zeros(no_comps,1)];
new_comp_dist = zeros(no_comps,1);
new_no_comps = no_comps; % We will update the number of compositions as we add new ones to the list
start_time=cputime;
for comp_no = 1:no_comps
    short_comp = two_class_with_repeats(comp_no,:);
    if short_comp(2)>0
        long_comp = composition_list(comp_no,:);
        P = zeros(1,short_comp(2)); % Vector containing probability that each of the adults present, ordered by age class, are vulnerable
        adults_present = 1+find(long_comp(2:end)>0); % List of adult classes present in detailed composition
        c = [0 cumsum(long_comp(adults_present))]; % Vector of cumulative adults present up to a given age class
        for i=1:length(adults_present)
            P(c(i)+1:c(i+1)) =... This is positions of age class i adults in P (indices are shifted up by 1 since we're searching over 2:end)
                sba(adults_present(i))*ones(1,long_comp(adults_present(i)));
        end
        base_prob = composition_dist(comp_no); % Probability of each assignment is conditional on this, the prob of being in the composition
        new_comp_dist(comp_no) = prod((1-P))*base_prob; % Probability no adults are vulnerable
        for i = 1:short_comp(2)-1
            new_no_comps = new_no_comps+1;
            new_comp_list(new_no_comps,:) = [short_comp(1), short_comp(2)-i, i]; % Append composition with i vulnerables
            prob = 0;
            vuln_grid = nchoosek(1:short_comp(2),i); % This outputs all combinations of i elements from set of adults
            no_combs = size(vuln_grid,1);
            for j=1:no_combs
                prob = prob + prod(P(vuln_grid(j,:)))*prod((1-P(setdiff(1:short_comp(2),vuln_grid(j,:)))));
            end
            new_comp_dist(new_no_comps) = prob*base_prob;
        end
        % Finally add the composition with all adults vulnerable
        new_no_comps = new_no_comps+1;
        new_comp_list(new_no_comps,:) = [short_comp(1), 0, short_comp(2)];
        new_comp_dist(new_no_comps) = prod(P)*base_prob;
    else
        new_comp_dist(comp_no) = composition_dist(comp_no); % If no one is over 19 we just have original composition
    end
    disp([num2str(comp_no) ' of ' num2str(no_comps) ' compositions done in '...
        num2str(cputime-start_time) ' seconds. Estimated '...
        num2str((cputime-start_time)*(no_comps-comp_no)/comp_no) ' remaining.']);
end

% We now filter the repeated compositions and add together their
% probabilities, converting them to integers first to make the necessary
% find operations less intensive.
max_by_class = [max(two_class_with_repeats) max(two_class_with_repeats(:,2))];
encoder = [1 cumprod(1+max_by_class(1:end-1))];
encoded_list = new_comp_list*encoder';
unique_encoded_list = unique(encoded_list);
no_encoded_states = length(unique_encoded_list);
unique_comp_list = zeros(no_encoded_states,3);
unique_comp_dist = zeros(no_encoded_states,1);
for i=1:no_encoded_states
    where_state = find(encoded_list==unique_encoded_list(i));
    unique_comp_list(i,:) = new_comp_list(where_state(1),:);
    unique_comp_dist(i) = sum(new_comp_dist(where_state));
end

% We can also check how big an age-and-household-structured epidemic model
% with a given number of compartments will be (this is useful for deciding
% computational requirements for a model using the household data):
disp(['With three epidemic compartments, system size will be ',...
    num2str(calculate_system_size(unique_comp_list,3)), '.']);
disp(['With four epidemic compartments, system size will be ',...
    num2str(calculate_system_size(unique_comp_list,4)), '.']);
disp(['With five epidemic compartments, system size will be ',...
    num2str(calculate_system_size(unique_comp_list,5)), '.']);
disp(['With six epidemic compartments, system size will be ',...
    num2str(calculate_system_size(unique_comp_list,6)), '.']);