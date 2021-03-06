%%
clear; clc;

num_neurons = [128, 128, 128, 128];
numlayer = numel(num_neurons);

Wix = cell(2,1);
Wih = cell(2,1);
Wic = cell(2,1);

Wfx = cell(2,1);
Wfh = cell(2,1);
Wfc = cell(2,1);

Wcx = cell(2,1);
Wch = cell(2,1);

Wox = cell(2,1);
Woh = cell(2,1);
Woc = cell(2,1);

for i = 1:2
    Wix{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Wih{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Wic{i} = 0.0006 * ones(num_neurons(i+1), 1);
    
    Wfx{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Wfh{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Wfc{i} = 0.0006 * ones(num_neurons(i+1), 1);
    
    Wcx{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Wch{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    
    Wox{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Woh{i} = 0.0006 * ones(num_neurons(i), num_neurons(i+1));
    Woc{i} = 0.0006 * ones(num_neurons(i+1), 1);

    GWix{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWih{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWic{i} = zeros(num_neurons(i+1), 1);
    
    GWfx{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWfh{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWfc{i} = zeros(num_neurons(i+1), 1);
    
    GWcx{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWch{i} = zeros(num_neurons(i), num_neurons(i+1));
    
    GWox{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWoh{i} = zeros(num_neurons(i), num_neurons(i+1));
    GWoc{i} = zeros(num_neurons(i+1), 1);
end

W = 0.0003 * ones(num_neurons(numlayer), num_neurons(numlayer-1)+1);
GW = zeros(num_neurons(numlayer), num_neurons(numlayer-1)+1);

%% input and output
max_seq = 2;
inputs = reshape((0:max_seq*num_neurons(1)-1), num_neurons(1), max_seq); %./ max_seq*num_neurons(1);
outputs = (max_seq*num_neurons(1) - reshape((0:max_seq*num_neurons(1)-1), num_neurons(1), max_seq)); %./ max_seq*num_neurons(1);

%%
lstmnum = 2;
lstms = cell(lstmnum, 1);

for i=1:lstmnum
    lstm.states         = zeros(num_neurons(i+1), max_seq+2);
    lstm.inputs         = zeros(num_neurons(i+1), max_seq+2);
    lstm.outputs        = zeros(num_neurons(i+1), max_seq+2);
    lstm.inGate         = zeros(num_neurons(i+1), max_seq+2);
    lstm.foGate         = zeros(num_neurons(i+1), max_seq+2);
    lstm.preStates      = zeros(num_neurons(i+1), max_seq+2);
    lstm.ouGate         = zeros(num_neurons(i+1), max_seq+2);
    lstm.preOutActs     = zeros(num_neurons(i+1), max_seq+2);
    
    lstm.inErrs         = zeros(num_neurons(i+1), max_seq+2);
    lstm.outErrs        = zeros(num_neurons(i+1), max_seq+2);
    lstm.spatialoutErrs = zeros(num_neurons(i+1), max_seq+2);
    lstm.statesErrs     = zeros(num_neurons(i+1), max_seq+2);
    lstm.inGateDelta    = zeros(num_neurons(i+1), max_seq+2);
    lstm.foGateDelta    = zeros(num_neurons(i+1), max_seq+2);
    lstm.ouGateDelta    = zeros(num_neurons(i+1), max_seq+2);
    lstm.preStatesDelta = zeros(num_neurons(i+1), max_seq+2);

    lstms{i} = lstm;
end

softmaxRes = zeros(num_neurons(numlayer), max_seq+2);

sigmoid = @(x) 1 ./ (1 + exp(-x));
sigmDeriv = @(x) (1-x) .* x;
tanhDeriv = @(x) (1 - x .^ 2);

%%
for i=2:max_seq+1
    disp(int2str(i))
    lstms{1}.inputs(:,i) = inputs(:,i-1);
    for j=1:lstmnum        
        lstms{j}.inGate(:,i)     = sigmoid (Wix{j} * lstms{j}.inputs(:,i) + Wih{j} * lstms{j}.outputs(:,i-1) + Wic{j} .* lstms{j}.states(:,i-1));
        lstms{j}.foGate(:,i)     = sigmoid (Wfx{j} * lstms{j}.inputs(:,i) + Wfh{j} * lstms{j}.outputs(:,i-1) + Wfc{j} .* lstms{j}.states(:,i-1));
        lstms{j}.preStates(:,i)  = tanh(Wcx{j} * lstms{j}.inputs(:,i) + Wch{j} * lstms{j}.outputs(:,i-1));
        lstms{j}.states(:,i)     = lstms{j}.foGate(:,i) .* lstms{j}.states(:,i-1) + lstms{j}.inGate(:,i) .* lstms{j}.preStates(:,i);
        lstms{j}.ouGate(:,i)     = sigmoid (Wox{j} * lstms{j}.inputs(:,i) + Woh{j} * lstms{j}.outputs(:,i-1) + Woc{j} .* lstms{j}.states(:,i));
        lstms{j}.preOutActs(:,i) = tanh(lstms{j}.states(:,i));
        lstms{j}.outputs(:,i)    = lstms{j}.ouGate(:,i) .* lstms{j}.preOutActs(:,i);
        if j < lstmnum
            lstms{j+1}.inputs(:,i) = lstms{j}.outputs(:,i);
        end
    end
    softmaxRes(:,i) = W * [lstms{lstmnum}.outputs(:,i); 1];
    % softmaxRes(:,i) = exp(softmaxRes(:,i)) / sum(exp(softmaxRes(:,i)));
end

%%

error_sig = (softmaxRes(:,2:max_seq+1) - outputs);

GW = GW + error_sig * [lstms{lstmnum}.outputs(:,2:max_seq+1); ones(1, max_seq)]';

spatialoutErrs = W' * error_sig;
spatialoutErrs = spatialoutErrs(1:end-1,:);

%%
for i=max_seq+1:-1:2
    disp(int2str(i))
    lstms{lstmnum}.spatialoutErrs(:,i) = spatialoutErrs(:,i-1);
    for j=lstmnum:-1:1
        if j < lstmnum
            lstms{j}.spatialoutErrs(:,i) = lstms{j+1}.inErrs(:,i);
        end
        lstms{j}.outErrs(:,i) = lstms{j}.spatialoutErrs(:,i) ...
                       + Wih{j}' * lstms{j}.inGateDelta(:,i+1)    + Wfh{j}' * lstms{j}.foGateDelta(:,i+1) ...
                       + Wch{j}' * lstms{j}.preStatesDelta(:,i+1) + Woh{j}' * lstms{j}.ouGateDelta(:,i+1);

        lstms{j}.ouGateDelta(:,i) = lstms{j}.outErrs(:,i) .* sigmDeriv(lstms{j}.ouGate(:,i)) .* lstms{j}.preOutActs(:,i);

        lstms{j}.statesErrs(:,i) = lstms{j}.outErrs(:,i) .* lstms{j}.ouGate(:,i) .* tanhDeriv(lstms{j}.preOutActs(:,i)) ...
                                 + lstms{j}.statesErrs(:,i+1) .* lstms{j}.foGate(:,i+1) ...
                                 + Wic{j} .* lstms{j}.inGateDelta(:,i+1) ...
                                 + Wfc{j} .* lstms{j}.foGateDelta(:,i+1) ...
                                 + Woc{j} .* lstms{j}.ouGateDelta(:,i);

        lstms{j}.preStatesDelta(:,i) = lstms{j}.statesErrs(:,i) .* lstms{j}.inGate(:,i)    .* tanhDeriv(lstms{j}.preStates(:,i));
        lstms{j}.foGateDelta(:,i)    = lstms{j}.statesErrs(:,i) .* lstms{j}.states(:,i-1)  .* sigmDeriv(lstms{j}.foGate(:,i));
        lstms{j}.inGateDelta(:,i)    = lstms{j}.statesErrs(:,i) .* lstms{j}.preStates(:,i) .* sigmDeriv(lstms{j}.inGate(:,i));
        
        lstms{j}.inErrs(:,i) = Wix{j}' * lstms{j}.inGateDelta(:,i)    + Wfx{j}' * lstms{j}.foGateDelta(:,i) ...
                             + Wcx{j}' * lstms{j}.preStatesDelta(:,i) + Wox{j}' * lstms{j}.ouGateDelta(:,i);

        GWix{j} = GWix{j} + lstms{j}.inGateDelta(:,i) * lstms{j}.inputs(:,i)';
        GWih{j} = GWih{j} + lstms{j}.inGateDelta(:,i) * lstms{j}.outputs(:,i-1)';
        GWic{j} = GWic{j} + lstms{j}.inGateDelta(:,i) .* lstms{j}.states(:,i-1);
               
        GWfx{j} = GWfx{j} + lstms{j}.foGateDelta(:,i) * lstms{j}.inputs(:,i)';
        GWfh{j} = GWfh{j} + lstms{j}.foGateDelta(:,i) * lstms{j}.outputs(:,i-1)';
        GWfc{j} = GWfc{j} + lstms{j}.foGateDelta(:,i) .* lstms{j}.states(:,i-1);

        GWcx{j} = GWcx{j} + lstms{j}.preStatesDelta(:,i) * lstms{j}.inputs(:,i)';
        GWch{j} = GWch{j} + lstms{j}.preStatesDelta(:,i) * lstms{j}.outputs(:,i-1)';
        
        GWox{j} = GWox{j} + lstms{j}.ouGateDelta(:,i) * lstms{j}.inputs(:,i)';
        GWoh{j} = GWoh{j} + lstms{j}.ouGateDelta(:,i) * lstms{j}.outputs(:,i-1)';
        GWoc{j} = GWoc{j} + lstms{j}.ouGateDelta(:,i) .* lstms{j}.states(:,i-1);
    end
end

