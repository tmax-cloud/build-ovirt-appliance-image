# build-ovirt-appliance-image

## 1. koji client 환경 로드
* koji client 이미지 실행
  * docker registry (ck2-2)
    * `192.168.2.242:32500/prolinux-ova-builder:8.2`
  * docker image (gz)
    * [pl-8.2-docker-ova-gen.tar.gz](http://192.168.2.136/prolinux/8.2/images/pl-8.2-docker-ova-gen.tar.gz)

* 실행한 docker image에서 koji 정상 동작 확인
  * koji cluster의 DNS가 서버에 등록되어있지 않아 추가 설정 필요
  * tmax 계정으로 koji에 접근 가능
```bash
  [root@1d8e135860f0 /]# echo "192.168.9.54 prolinux-koji-el8.tk" >> /etc/hosts
  [root@1d8e135860f0 /]# su tmax
  [tmax@1d8e135860f0 /]$ koji hello
  안녕하세요, tmax!
  
  You are using the hub at https://prolinux-koji-el8.tk/kojihub
  Authenticated via client certificate /home/tmax/.koji/client.crt
```
## 2. OVA 빌드 설정
```bash
  [root@1d8e135860f0 /]# dnf install git -y
  [tmax@1d8e135860f0 ~]$ git clone https://github.com/tmax-cloud/build-ovirt-appliance-image.git
  [tmax@1d8e135860f0 ~]$ cd ./build-ovirt-appliance-image
```

## 3. koji image build 명령어 실행
```bash
  [tmax@1d8e135860f0 ~]$ koji image-build --config ./configs/ovirt-appliance-koji.cfg --scratch
```
* [koji-web](http://192.168.9.54/koji)에서 작업 현황 및 결과물 확인



