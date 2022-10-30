vm(0,12,0).
vm(1,23,2).
vm(2,94,4).
vm(3,35,6).
vm(4,15,8).
vm(5,4,10).
vm(6,0,12).
vm(7,17,14).
vm(8,2,16).
vm(9,11,18).
vm(10,10,1).
vm(11,57,3).
vm(12,1,5).
vm(13,24,7).
vm(14,124,9).
vm(15,5,11).
vm(16,7,13).
vm(17,0,15).
vm(18,0,17).
vm(19,12,19).
vm(20,1,0).
vm(21,11,2).
vm(22,4,4).
vm(23,5,6).
vm(24,1,8).
vm(25,6,10).
vm(26,12,7).
vm(27,10,9).
vm(28,1,11).
vm(29,10,13).
vm(30,54,15).
vm(31,15,17).
vm(32,4,19).
vm(33,8,12).
vm(34,0,14).
vm(35,0,16).
vm(36,1,18).
vm(37,4,1).
vm(38,4,3).
vm(39,0,5).
vm(40,20,5).
vm(41,0,7).
vm(42,0,9).
vm(43,5,11).
vm(44,0,13).
vm(45,8,15).
vm(46,0,17).
vm(47,5,19).
vm(48,3,12).
vm(49,5,14).

host(0,1200).
host(1,1200).
host(2,1200).
host(3,1200).
host(4,1200).
host(5,1200).
host(6,1200).
host(7,1200).
host(8,1200).
host(9,1200).
host(10,1200).
host(11,1200).
host(12,1200).
host(13,1200).
host(14,1200).
host(15,1200).
host(16,1200).
host(17,1200).
host(18,1200).
host(19,1200).

%统计在调度前各个host一共占用了多少资源
used_host(HID,USED_C) :- USED_C=#sum{ C,ID: vm(ID,C,HID)},host(HID,_).

% 计算在调度前所有主机的cpu使用率
cpu_usage_rate(HID,V) :- V = USED_C*100/ALL_C, used_host(HID,USED_C), host(HID,ALL_C).

% 对于资源使用率在80以上的主机的vm，实施迁移操作，将其vm迁移到80以下的host中
% 将位于HID1主机上的vm转移到HID2上
{transfer_vm(ID,C,HID2)} :- cpu_usage_rate(HID1,V1),V1>80,cpu_usage_rate(HID2,V2),V2<80,vm(ID,C,HID1),HID1!=HID2.


% 对于资源使用率在40以下的host，将其vm迁移到80以下的host中
{transfer_vm(ID,C,HID2)} :- cpu_usage_rate(HID1,V1),V1<40,cpu_usage_rate(HID2,V2),V2<80,V2>0,vm(ID,C,HID1),HID1!=HID2.



% 对于那些剩余的vm，还在原来的位置运行
remain_vm(ID,C,HID) :- vm(ID,C,HID),not transfer_vm(ID,_,_).

%统计发生迁移的vm个数
all_transfer(X):- X=#count{ ID,ID: transfer_vm(ID,_,HID) }.

%7 迁移完成后各个host的cpu使用情况
transformed_used_host(HID,V) :- V=X+Y,X=#sum{C,ID:transfer_vm(ID,C,HID)},Y=#sum{C,ID:remain_vm(ID,C,HID)},host(HID,_).

% 迁移完成后各个主机的资源使用率（包含transfer和remain）
transformed_cpu_usage_rate(HID,V) :- V=USED_C*100/ALL_C,transformed_used_host(HID,USED_C),host(HID,ALL_C).

% 统计当前正在使用的主机
% 在这里，如果一个vm资源使用量是0，此时采取迁移的方式还是原地不动？如果使用率为0，那么此时应该也不会消耗过多资源
%using_host(X) :- X= #count{V,HID:transformed_cpu_usage_rate(HID,V),V!=0}.
%using_host(X) :- X= #count{V,HID: transformed_used_host(HID,V),V!=0 }.
using_host(Z) :- X= #count{HID: remain_vm(_,_,HID) },Y=#count{HID: transfer_vm(_,_,HID)},Z=X+Y.


%%%完整性约束

% 不允许一个vm迁移多次
:- transfer_vm(ID1,_,HID1),transfer_vm(ID2,_,HID2),ID1=ID2,HID1!=HID2.

%不允许编号小的host使用率小于编号大的
:- transformed_used_host(HID1,V1),transformed_used_host(HID2,V2),HID1<HID2,V1<V2,V1<40.

%不允许host的资源利用率超过100
:- transformed_cpu_usage_rate(_,V),V>=100.

% #####优先为较小编号的服务器分配vm（这条语句只是为了缩小回答集范围），即：不会出现编号大的服务器启用，编号小的服务器空闲的现象
:- transformed_used_host(HID1,V),transformed_used_host(HID2,0),HID1>HID2,V>0.

%%%%%%%软约束%%%%%%%

% 统计迁移的vm的个数，要求vm迁移个数尽可能小。  8
#minimize{X@8:all_transfer(X)}.

% 要求使用中的host数量尽可能少。 9
#minimize{X@9:using_host(X)}.

% 要求使用中的host尽量在400-800间。10

#maximize{N@10:N=V-40,transformed_cpu_usage_rate(_,V),using_host(X),V>40,V!=0}.
#minimize{N@11:N=|V-80|,transformed_cpu_usage_rate(_,V),using_host(X),V!=0}.
%#minimize{N@11:N=|V-80|,transformed_cpu_usage_rate(_,V),using_host(X)}.


#show remain_vm/3.
#show transfer_vm/3.

%#show cpu_usage_rate/2.
%#show used_host/2.
%#show transformed_used_host/2.
%#show transformed_cpu_usage_rate/2.
%#show using_host/1.
%#show all_transfer/1.
