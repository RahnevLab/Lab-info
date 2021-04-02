%analysis_expt1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: cond==0: No Feedback,  cond==1: Feedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all
clc

% Add helper functions
addpath(genpath(fullfile(pwd, 'helperFunctions')));

% Decide on whether to compute or load meta scores
compute_metacognition = 0;
perform_hierarchical_estimation = 0;

% Filters for each task
filter{1} = [ones(1,330),zeros(1,150)]; %trials 1 to 330 are from Task 1
filter{2} = [zeros(1,330),ones(1,150)]; %trials 331 to 480 are from Task 2

% Filters for Task 2 trials
filter_trials{1} = [zeros(1,330),ones(1,10),zeros(1,140)]; %first 10 trials from Task 2
filter_trials{2} = [zeros(1,330),ones(1,20),zeros(1,130)]; %first 20 trials from Task 2
filter_trials{3} = [zeros(1,330),ones(1,30),zeros(1,120)]; %first 30 trials from Task 2
filter_trials{4} = [zeros(1,330),ones(1,40),zeros(1,110)]; %first 40 trials from Task 2
filter_trials{5} = [zeros(1,330),ones(1,50),zeros(1,100)]; %first 50 trials from Task 2
filter_trials{6} = [zeros(1,330),ones(1,60),zeros(1,90)]; %first 60 trials from Task 2

% Filters for mini blocks analyses
blocks_size = 10;
for filt=1:330/blocks_size
    filters{filt} = [zeros(1,(filt-1)*blocks_size), ones(1,blocks_size), zeros(1,330-filt*blocks_size), zeros(1,150)];
end

% To run Task 1 analyses only on second half, uncomment line below
%filter{1} = [zeros(1,165), ones(1,165), zeros(1,150)]; %2nd half Task 1

% Decide on exclusion cutoffs
RT_cutoffs = [200, 2000]; %in ms for individual trials
acc_cutoffs = [.55, .95]; %accuracy for a given task

% Load the data
load data

% Loop over all subjects
for sub=1:length(data)
    
    % Create an RT filter
    filter_rt_dec = data{sub}.rt_dec > RT_cutoffs(1) & data{sub}.rt_dec < RT_cutoffs(2);
    filter_rt_conf = data{sub}.rt_conf > RT_cutoffs(1) & data{sub}.rt_conf < RT_cutoffs(2);
    
    % Compute bias for mini blocks in Task 1
    for filt=1:330/blocks_size
        trial_filter = filters{filt} & filter_rt_dec(1:480);
        [~, c_block(sub,filt)] = data_analysis_resp(data{sub}.stim(trial_filter), data{sub}.resp(trial_filter));
    end
    
    % Compute d', c, mean conf, RT_dec, RT_conf, and Mratio
    for task=1:2
        trial_filter = filter{task} & filter_rt_dec(1:480);
        [dprime(sub,task), c(sub,task)] = data_analysis_resp(data{sub}.stim(trial_filter), data{sub}.resp(trial_filter));
        conf(sub,task) = mean(data{sub}.conf(trial_filter));
        accuracy(sub,task) = mean(data{sub}.correct(trial_filter));
        rt_dec(sub,task) = mean(data{sub}.rt_dec(trial_filter));
        rt_conf(sub,task) = mean(data{sub}.rt_conf(filter{task} & filter_rt_conf));
        learning_rate(sub,task,:) = regress(data{sub}.correct(filter{task}==1)', ...
            [ones(1,sum(filter{task})); 1:sum(filter{task})]');
        r_conf_RT(sub,task) = corr(data{sub}.rt_dec(filter{task}==1)', data{sub}.conf(filter{task}==1)');
        rt_error_minus_correct(sub,task) = mean(data{sub}.rt_dec(trial_filter & data{sub}.stim ~= data{sub}.resp)) - ...
            mean(data{sub}.rt_dec(trial_filter & data{sub}.stim == data{sub}.resp));
        [FAR(sub,task,:),HR(sub,task,:)] = computeROC(data{sub}.stim(trial_filter),data{sub}.resp(trial_filter),data{sub}.conf(trial_filter),4);
        
        % Compute metacognition
        if compute_metacognition
            if sub==108  % this subject doesn't have any good trials
                da(sub,task) = NaN;
                metad(sub,task) = NaN;
                Mratio(sub,task) = NaN;
            else
                output = type2_SDT_MLE(data{sub}.stim(trial_filter), ...
                    data{sub}.resp(trial_filter), ...
                    data{sub}.conf(trial_filter), 4, [], 1);
                da(sub,task) = output.da;
                metad(sub,task) = output.meta_da;
                Mratio(sub,task) = output.M_ratio;
            end
        end
        
        % Compute EZ diffusion parameters
        Pc = accuracy(sub,task);
        RT_mean = rt_dec(sub,task)/1000;
        RT_var = var(data{sub}.rt_dec(trial_filter)/1000);
        [v(sub,task), a(sub,task), Ter(sub,task)] = EZdiff(Pc, RT_mean, RT_var);
        
        
    end
    

    % Compute accuracy for first 10, 20, 30, 40, 50, 60 trials of Task 2
    for trials = 1:6
    trial_filter = filter_trials{trials} & filter_rt_dec(1:480);
    accuracy_initial_trials(sub,trials) = mean(data{sub}.correct(trial_filter));
    end

    
    % Determine the condition for each subject
    cond(sub) = data{sub}.cond;
    
    % Compute d' for last N blocks (N from 1 to 10)
    for N=1:10
        filter_last_N_blocks = [zeros(1,(11-N)*30),ones(1,N*30),zeros(1,150)];
        dprime_last_N_blocks(sub,N) = data_analysis_resp(data{sub}.stim(filter_last_N_blocks&filter_rt_dec), ...
            data{sub}.resp(filter_last_N_blocks&filter_rt_dec));
    end
    
    % Compute slope for learning on Task 1
    Y = data{sub}.correct(filter{1}==1)'; %accuracy
    X = [ones(sum(filter{1}),1), [1:sum(filter{1})]']; %constant + trial number
    betas = regress(Y, X); %run regression
    slope_task1(sub) = betas(2); %save slope (beta value for trial number)
    
    % Compute slope for learning on Task 2
    Y = data{sub}.correct(filter{2}==1)'; %accuracy
    X = [ones(sum(filter{2}),1), [1:sum(filter{2})]']; %constant + trial number
    betas = regress(Y, X); %run regression
    slope_task2(sub) = betas(2); %save slope (beta value for trial number)
    

end

% % Load meta results if they were not computed this time
if compute_metacognition
    save metaResults da metad Mratio
else
    load metaResults
end


%% Do analyses for each task separately
for task=1:2
    fprintf(['\n--------------- Task ' num2str(task) ' results -----------\n']);
    
    % Determine the good subjects
    gd_subj{task} = accuracy(:,task)' >= acc_cutoffs(1) & accuracy(:,task)' <= acc_cutoffs(2);
    F{task} = gd_subj{task} & cond==1; %Feedback group
    NF{task} = gd_subj{task} & cond==0; %No Feedback group
    
    % Type I performance: d'
    dprime_means = [mean(dprime(F{task},task)), mean(dprime(NF{task},task))]
    perform_ttest2(dprime(F{task},task),dprime(NF{task},task),['Task ' num2str(task) ', dprime'], 1);
    
    % Accuracy
    accuracy_means = [mean(accuracy(F{task},task)), mean(accuracy(NF{task},task))]
    perform_ttest2(accuracy(F{task},task),accuracy(NF{task},task),['Task ' num2str(task) ', accuracy'], 1);
    
    % Type I bias: c
    c_means = [mean(c(F{task},task)), mean(c(NF{task},task))]
    c_stds = [std(c(F{task},task)), std(c(NF{task},task))]
    perform_ttest2(c(F{task},task),c(NF{task},task),['Task ' num2str(task) ', Criterion c'], 1);
    [~,p_varCmp,~,stats_varCmp] = vartest2(c(F{task},task), c(NF{task},task))
    absc = abs(c);
    [p_absc,~,stats_absc] = ranksum(absc(F{task},task),absc(NF{task},task)) % Absolute Criterion c
 
    
    % Type II sensitivity: meta-d'
    metad_means = [mean(metad(F{task},task)), mean(metad(NF{task},task))]
    perform_ttest2(metad(F{task},task),metad(NF{task},task),['Task ' num2str(task) ', Meta-d'''], 1);
    
    % Type II bias: d'- conf correlation
    [r(1),p_corr(1)] = corr(dprime(F{task},task),conf(F{task},task));
    [r(2),p_corr(2)] = corr(dprime(NF{task},task),conf(NF{task},task));
    dprime_conf_corr_r_and_p = [r; p_corr]
    [z_compare_r_values_dconf,p_compare_r_values_dconf] = compare_r1_r2(r(1),r(2),sum(F{task}),sum(NF{task}))
    
    % RT_dec analyses
    RT_dec_means = [mean(rt_dec(F{task},task)), mean(rt_dec(NF{task},task))]
    perform_ttest2(rt_dec(F{task},task),rt_dec(NF{task},task),['Task ' num2str(task) ', RT_dec'], 1);
    
    % RT_conf analyses
    RT_conf_means = [mean(rt_conf(F{task},task)), mean(rt_conf(NF{task},task))]
    perform_ttest2(rt_conf(F{task},task),rt_conf(NF{task},task),['Task ' num2str(task) ', RT_conf'], 1)
    
    % Compute d' and Mratio using Hierarchical HMetad (Fleming, 2017)
    if perform_hierarchical_estimation
        for group=1:2 %group==1: F, group==2: NF
            [~,idx] = find(gd_subj_F_NF{group}==1);
            for sub=1:length(idx)
                nR_S1_gr{group}{sub} = nR_S1{task,idx(sub)};
                nR_S2_gr{group}{sub} = nR_S2{task,idx(sub)};
            end
            fit{task,group} = fit_meta_d_mcmc_group(nR_S1_gr{group}, nR_S2_gr{group});
        end
        save HMetad2 fit
    end
end


%% Additional Task 1 analyses
fprintf(['\n\n--------------- Additional Task 1 analyses  -----------\n\n']);
task = 1;

% Correlation confidence ratings and decision RT within-subjects
fprintf(['\nTask ' num2str(task) ' t-test on confidence-rt correlation within subjects:\n']);
perform_ttest(rt_error_minus_correct(gd_subj{task},1),'T-test on RT_error-RT_correct', 1);
perform_ttest(r2z(r_conf_RT(gd_subj{task},1)),'T-test on conf-RT correlation', 1);

% Correlation of learning rate with d' and meta d' across groups
fprintf(['\nTask ' num2str(task) ' Correlation of learning rate with d'' and meta-d'' across groups:\n']);
[r_dprime,p] = corr(learning_rate(gd_subj{1},1,2), dprime(gd_subj{1},1))
[r_metad,p] = corr(learning_rate(gd_subj{1},1,2), metad(gd_subj{1},1))


%% EZ drift diffusion results
fprintf(['\nTask ' num2str(task) ' Drift Diffusion Modeling results:\n']);
v_means = [mean(v(F{1,1},task)), mean(v(NF{1,1},task))]
perform_ttest2(v(F{1,1},task),v(NF{1,1},task),['Task ' num2str(task) ', v'], 1);
Ter_means = [mean(Ter(F{1,1},task)), mean(Ter(NF{1,1},task))]
perform_ttest2(Ter(F{1,1},task),Ter(NF{1,1},task),['Task ' num2str(task) ', Ter'], 1);
a_means = [mean(a(F{1,1},task)), mean(a(NF{1,1},task))]
perform_ttest2(a(F{1,1},task),a(NF{1,1},task),['Task ' num2str(task) ', a'], 1);


%% Hieratchical estimation results
fprintf(['\n\n\nTask ' num2str(task) ' Hierarchical Mratio:\n']);
if perform_hierarchical_estimation==0 
    load hierarchd
    load hierarchMratio
end

hdi_Mratio_Task1 = calc_HDI(sampleDiffMratioTask1(:))

%Hierarchical d'
fprintf(['\nTask ' num2str(task) ' Hierarchical d'':\n']);
hdi_d_Task1 = calc_HDI(sampleDiffdTask1(:))


%% Bias in mini blocks in Task 1
for filt=1:330/blocks_size
    c_vars(filt,:) = [nanvar(c_block(cond==1,filt)), nanvar(c_block(cond==0,filt))];
    [~,p_varCmp(filt)] = vartest2(c_block(cond==1,filt), c_block(cond==0,filt));
end
plot_lines(c_vars);
p_varCmp


%% T-test for slope in Task 1
task = 1;
fprintf(['\n--------------- Task ' num2str(task) ' slope -----------\n']);

slope_means = [mean(slope_task1(F{task})), mean(slope_task1(NF{task}))]
[~,p_slopeFnoteq0,~,stats] = ttest(slope_task1(F{task}))
[~,p_slopeNFnoteq0,~,stats] = ttest(slope_task1(NF{task}))
perform_ttest2_tail_right(slope_task1(F{task}),slope_task1(NF{task}),['Task ' num2str(task) ', slopeF_vs_NF'], 1)
task = 1;
slopeF1 = slope_task1(F{task})';
slopeNF1 = slope_task1(NF{task})';


%% T-test for slope in Task 2
    
task = 2;
fprintf(['\n--------------- Task ' num2str(task) ' slope -----------\n']);

slope_means = [mean(slope_task2(F{task})), mean(slope_task2(NF{task}))]
[~,p_slopeFnoteq0,~,stats] = ttest(slope_task2(F{task}))
[~,p_slopeNFnoteq0,~,stats] = ttest(slope_task2(NF{task}))
perform_ttest2_tail_right(slope_task2(F{task}),slope_task2(NF{task}),['Task ' num2str(task) ', slopeF_vs_NF'], 1)
task = 2;
slopeF2 = slope_task2(F{task})';
slopeNF2 = slope_task2(NF{task})';


%% T-tests for d' in last N blocks in Task 1
task = 1;
fprintf('\n--------------- T-tests for d'' in last N blocks in Task 1 -----------\n');
for block_num=1:10
    [~,p_dprimeblock(block_num)] = ttest2(dprime_last_N_blocks(F{task}, block_num), dprime_last_N_blocks(NF{task}, block_num));
end
p_dprimeblock

%% RT decision difference analysis comparing Task 1 and Task 2
fprintf(['\n--------------- Decision RT difference between groups in Task 1 and Task 2  -----------\n']);
%Good subjects for both Task1 and Task2
gd_subj_both = gd_subj{1,1} ==1 & gd_subj{1,2} ==1;

for task = 1:2
    t1t2gdsubj.(['task' num2str(task)]).cond = cond(gd_subj_both)';
    t1t2gdsubj.(['task' num2str(task)]).rt_dec = rt_dec(gd_subj_both, task);
end

FT1_minus_FT2 = t1t2gdsubj.task1.rt_dec(t1t2gdsubj.task1.cond==1) - t1t2gdsubj.task2.rt_dec(t1t2gdsubj.task2.cond==1);
NFT1_minus_NFT2 = t1t2gdsubj.task1.rt_dec(t1t2gdsubj.task1.cond==0) - t1t2gdsubj.task2.rt_dec(t1t2gdsubj.task2.cond==0);
perform_ttest2(FT1_minus_FT2, NFT1_minus_NFT2,'Decision RT diff b/n Tasks 1 and 2', 1);


%% Determine power for a smaller experiment for RT
fprintf(['\n--------------- Simulate power for RT results in Expt 2  -----------\n']);
prop_sign_RT_dec = simulateSmallerExpt_RT(rt_dec(F{1},1), rt_dec(NF{1},1), 10000, 30)
prop_sign_RT_conf = simulateSmallerExpt_RT(rt_conf(F{1},1), rt_conf(NF{1},1), 10000, 30)



%% Determine power for a smaller experiment for Criterion c
fprintf(['\n--------------- Simulate power for Criterion c results in Expt 2  -----------\n']);
prop_sign_absc = simulateSmallerExpt_c(absc(F{1},1), absc(NF{1},1), 10000, 30)
prop_sign_cvar = simulateSmallerExpt_cvar(c(F{1},1), c(NF{1},1), 10000, 30)


%% Accuracy for first 10, 20, 30, 40, 50, 60 trials of Task 2

    accuracy_initial_means10 = [nanmean(accuracy_initial_trials(F{2},1)), nanmean(accuracy_initial_trials(NF{2},1))]
    perform_ttest2(accuracy_initial_trials(F{2},1),accuracy_initial_trials(NF{2},1),'Task 2 , accuracy first 10 trials', 1);
    
    accuracy_initial_means20 = [nanmean(accuracy_initial_trials(F{2},2)), nanmean(accuracy_initial_trials(NF{2},2))]
    perform_ttest2(accuracy_initial_trials(F{2},2),accuracy_initial_trials(NF{2},2),'Task 2 , accuracy first 20 trials', 1);
    
    accuracy_initial_means30 = [nanmean(accuracy_initial_trials(F{2},3)), nanmean(accuracy_initial_trials(NF{2},3))]
    perform_ttest2(accuracy_initial_trials(F{2},3),accuracy_initial_trials(NF{2},3),'Task 2 , accuracy first 30 trials', 1);

    accuracy_initial_means40 = [nanmean(accuracy_initial_trials(F{2},4)), nanmean(accuracy_initial_trials(NF{2},4))]
    perform_ttest2(accuracy_initial_trials(F{2},4),accuracy_initial_trials(NF{2},4),'Task 2 , accuracy first 40 trials', 1);
    
    accuracy_initial_means50 = [nanmean(accuracy_initial_trials(F{2},5)), nanmean(accuracy_initial_trials(NF{2},5))]
    perform_ttest2(accuracy_initial_trials(F{2},5),accuracy_initial_trials(NF{2},5),'Task 2 , accuracy first 50 trials', 1);

    accuracy_initial_means60 = [nanmean(accuracy_initial_trials(F{2},6)), nanmean(accuracy_initial_trials(NF{2},6))]
    perform_ttest2(accuracy_initial_trials(F{2},6),accuracy_initial_trials(NF{2},6),'Task 2 , accuracy first 60 trials', 1);

%% DDM model fit on single subjects Experiment 1

%load DDM parameters
load DDM_param

% Which single subject
sub = 75; %75, 41, 43, 25 used in figure

% Real data rt and correct trials
rt_filter = data{sub}.rt_dec > RT_cutoffs(1) & data{sub}.rt_dec < RT_cutoffs(2);
rt_real = data{sub}.rt_dec(rt_filter);
correct_real = data{sub}.correct(rt_filter);


% Decide on the number of trials per simulation
factor = 100; %the factor by which the simulated trials exceed the number of trials in the dataset
N = 480 * factor; %total number of trials


% Simulated data
% Set DDM parameters
a = a(sub,1);
v = v(sub,1);
eta = 0;
z = a/2;
sz = 0;
Ter = Ter(sub,1);
st = 0;



% Simulate the model
[choice, rt] = simulate_ddm(a, v, eta, z, sz, Ter, st, N);
rt = 1000 * rt;



%% Task 1 Figures
% Figure 2A: d'
d1.NF=dprime(NF{1,1},1);
d1.F=dprime(F{1,1},1);

figure;raincloud_wrapper(d1, 0, 'Perceptual sensitivity (d'')');
xlabel('d''')
xlim([-0.2 3.6])

% Figure 2B: meta-d'
md1.NF=metad(NF{1,1},1);
md1.F=metad(F{1,1},1);

figure;raincloud_wrapper(md1, 0, 'Metacognitive sensitivity (meta-d'')');
xlabel('meta-d''')
xlim([-1.2 4])

%  Figure 4: response criterion c
c1.NF=c(NF{1,1},1);
c1.F=c(F{1,1},1);

figure; raincloud_wrapper(c1, 0, 'Response bias (criterion c)');
xlabel('c')
xlim([-0.95 0.95])

% Figure 6A:
rtd1.NF=rt_dec(NF{1,1},1);
rtd1.F=rt_dec(F{1,1},1);

figure; raincloud_wrapper(rtd1, 0, 'Decision RT');
xlabel('Average decision RT')
xlim([200 1400])

% Figure 6B:
rtc1.NF=rt_conf(NF{1,1},1);
rtc1.F=rt_conf(F{1,1},1);

figure; raincloud_wrapper(rtc1, 0, 'Confidence RT');
xlabel('Average confidence RT')
xlim([150 1200])

% Task 1 Figure 5C bargraph (d' conf correlation comparison)
d1.NF=dprime(NF{1,1},1);
d1.F=dprime(F{1,1},1);
conf1.NF=conf(NF{1,1},1);
conf1.F=conf(F{1,1},1);

% Correlate d' and confidence seperately for feedback and no feedback
[r_dcF1, p] = corr(d1.F, conf1.F); % Feedback Task 1
[r_dcNF1, p] = corr(d1.NF, conf1.NF);% No Feedback Task 1

% Get values for error bars
r_upperF = z2r(r2z(r_dcF1)+1/sqrt(200-3));
r_upperNF = z2r(r2z(r_dcNF1)+1/sqrt(195-3));
r_lowerF = z2r(r2z(r_dcF1)-1/sqrt(200-3));
r_lowerNF = z2r(r2z(r_dcNF1)-1/sqrt(195-3));

% Bar graph
figure; x = categorical({'No Feedback','Feedback'});
x = reordercats(x,{'No Feedback','Feedback'});
y = [r_dcNF1, r_dcF1];
errhigh = [r_upperNF, r_upperF];
errlow = [r_lowerNF, r_lowerF];

bar(x,y, 0.5, 'FaceColor',[0.9990, 0.6940, 0.1250],'EdgeColor',[0 0 0],'LineWidth',0.8)
ylim([-0.2 0.7])
set(gca,'YLim', [-0.2, 0.7]);
ylabel('r-value')
box off
set(gca,'LineWidth',1,'TickLength',[0.012 0.012]);
set(gca,'FontSize',19)
hold on

er = errorbar(x,y,errlow,errhigh, 'LineWidth',0.8);
er.Color = [0 0 0];
er.LineStyle = 'none';


%% Task 2 Figures
% Figure 7A: d'
d2.NF=dprime(NF{1,2},2);
d2.F=dprime(F{1,2}, 2);

figure; raincloud_wrapper(d2, 0, 'Perceptual sensitivity (d'')');
xlabel('d''')
xlim([-.8 3.8])

% Figure 7B: meta-d'
md2.NF=metad(NF{1,2},2);
md2.F=metad(F{1,2}, 2);

figure; raincloud_wrapper(md2, 0, 'Metacognitive sensitivity (meta-d'')');
xlabel('meta-d''')
xlim([-2 4])

%  Figure 7C: response criterion c
c2.NF=c(NF{1,2},2);
c2.F=c(F{1,2}, 2);

figure; raincloud_wrapper(c2, 0, 'Response bias (criterion c)');
xlabel('c')
xlim([-1.8 1.8])

% Figure 7E: decision rt
rtd2.NF=rt_dec(NF{1,2},2);
rtd2.F=rt_dec(F{1,2}, 2);

figure; raincloud_wrapper(rtd2, 0, 'Decision RT');
xlabel('Average decision RT')
xlim([200 1400])

% Figure 7F: confidence rt
rtc2.NF=rt_conf(NF{1,2},2);
rtc2.F=rt_conf(F{1,2}, 2);

figure; raincloud_wrapper(rtc2, 0, 'Confidence RT');
xlabel('Average confidence RT')
xlim([150 1200])

%% DDM plots

% Plot real data + fit
bin = 20; 
subplot(1,2,1);  
hist(rt_real(correct_real==1),1:bin:3000, colormap(winter)); 
ylim([0, 23]);
xlim([0, max(rt_real)]); hold;
[n, x] = hist(rt(choice==1),1:bin:3000);
plot(x,n/factor, 'black', 'LineWidth', 3);
xlabel('Time (ms)')
ylabel('RT count (correct trials)')
box off
set(gca,'LineWidth',1,'TickLength',[0.012 0.012]);
set(gca,'FontSize',17)


subplot(1,2,2); 
hist(rt_real(correct_real==0),1:bin:3000); 
ylim([0, 23]);
xlim([0, max(rt_real)]); hold;
[n, x] = hist(rt(choice==0),1:bin:3000);
h1=plot(x,n/factor, 'black', 'LineWidth', 3);
xlabel('Time (ms)')
ylabel('RT count (error trials)')
box off
set(gca,'LineWidth',1,'TickLength',[0.012 0.012]);
set(gca,'FontSize',17)

l = legend(h1,'DDM simulated data','location','northeast');
set(gca,'fontsize',18)


%% ROC Supplementary Figure 1

% Plot ROC fits
figure('Color','w', 'DefaultAxesFontSize',16);
for task=1:2
    sub_num=0;
    for subject=[21,38,74]
        sub_num = sub_num+1;
        plot_ROC(dprime(subject,task), squeeze(HR(subject,task,:)), squeeze(FAR(subject,task,:)), sub_num, task)
    end
end
