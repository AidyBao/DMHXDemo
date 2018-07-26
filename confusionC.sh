#!/bin/sh
##################################
#  （该脚本是在https://github.com/heqingliang/CodeObfus 上找到的）
#  代码混淆脚本  heyujia 2018.03.15
#
##################################

#识别含有多字节编码字符时遇到的解析冲突问题
export LC_CTYPE=C
export LANG=C

#配置项：
#项目路径,会混淆该路径下的文件
ProjectPath="/Users/xieyujia/Desktop/ios/学习项目/daimahunxiao"
#这个路径是混淆成功后，原文本和替换文本解密对应的文件存放路径（该路径不能在项目目录或其子目录），混淆成功后会在该路径下生成一个解密时需要的文件，根据该文件的文本内容把混淆后的内容更换为原文本内容，该文件名的组成由$(date +%Y%m%d)"_"$(date +%H%M)及日期_小时组成，每分钟会不一样。所以解密的时候需要每次更换文件路径
SecretFile="/Users/xieyujia/Desktop/ios/学习项目/tihuan"$(date +%Y%m%d)"_"$(date +%H%M)

#第一个参数为项目路径
if [[ $1 ]]
then
if [[ $1 != "_" ]]; then
ProjectPath=$1
fi
fi
#第二个参数指定密钥文件路径及文件名
if [[ $2 ]]
then
if [[ $2 != "_" ]]; then
SecretFile=$2
fi
fi
##############################################################################

#查找文本中所有要求混淆的属性\方法\类，只会替换文本中ob_开头和_fus结尾的字符串（区分大小写，例如oB_就不会做混淆），如果注释内容有该类型的字符串，也会进行替换。对于使用 _下划线访问的变量属性，不会有影响，一样会替换成对应_的混淆内容。
resultfiles=`grep 'ob_[A-Za-z0-9_]*_fus' -rl $ProjectPath`
#查找结果为空则退出
if [[ -z $resultfiles ]]
then
echo "项目没有需要混淆的代码"
exit
else
echo "开始混淆代码..."
echo  > $SecretFile
fi

x=$(awk  '
BEGIN{srand();k=0;}
#随机数生成函数
function random_int(min, max) {
return int( rand()*(max-min+1) ) + min;
}
#随机字符串生成函数
function random_string(len) {
result="UCS"k;
alpbetnum=split("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z", alpbet, ",");
for (i=0; i<len; i++) {
result = result""alpbet[ random_int(1, alpbetnum) ];
}
return result;
}
/ob_[A-Za-z0-9_]*_fus/{
x = $0;
#匹配需要混淆的属性变量方法
while (match(x, "ob_[A-Za-z0-9_]*_fus") > 0) {
tempstr=substr(x, RSTART, RLENGTH);
#判断是否有之前已经找过的重复字符串
for ( i = 0; i < k; i++ ){
if (strarr[i] == tempstr){break;}
}
if(i<k){
#重复字符串，直接删除。所以不用担心混淆内容过多，可能会出现重复的混淆字符串
x=substr(x, RSTART+RLENGTH);
continue;
}else{
#不是重复字符串，添加到替换数组
strarr[k++]=tempstr;
}
randomstr=random_string(20);
printf("%s:%s|", tempstr,randomstr);
#替换随机字符串
gsub(tempstr,randomstr, x);
x = substr(x, RSTART+RLENGTH);
}
}' $resultfiles )

#加密对写入密钥文件
echo $x > $SecretFile

recordnum=1
while [[ 1 == 1 ]]; do
record=`echo $x|cut -d "|" -f$recordnum`
if [[ -z $record ]]
then
break
fi
record1=`echo $record|cut -d ":" -f1`
echo "原项:"$record1
record2=`echo $record|cut -d ":" -f2`
echo "加密项:"$record2
#替换文件夹中所有文件的内容（支持正则）
#单引号不能扩展
sed -i '' "s/${record1}/${record2}/g" `grep $record1 -rl $ProjectPath`
echo "第"$recordnum"项混淆代码处理完毕"
let "recordnum = $recordnum + 1"
done

#查找需要混淆的文件名并替换
filerecordnum=1
while [[ 1 == 1 ]]; do
filerecord=`echo $x|cut -d "|" -f$filerecordnum`
if [[ -z $filerecord ]]
then
break
fi
filerecord1=`echo $filerecord|cut -d ":" -f1`
#echo "原项:"$filerecord1
filerecord2=`echo $filerecord|cut -d ":" -f2`
#echo "加密项:"$filerecord2
#改文件名

find $ProjectPath -name $filerecord1"*"| awk '
BEGIN{frecord1="'"$filerecord1"'";frecord2="'"$filerecord2"'";finish=1}
{
filestr=$0;
gsub(frecord1,frecord2,filestr);
print "mv " $0 " " filestr";echo 第"finish"个混淆文件处理完毕";
finish++;
}'|bash
let "filerecordnum = $filerecordnum + 1"
done
