FROM quay.io/operator-framework/ansible-operator:v1.7.2

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

RUN pip install -U \
  openshift==0.12.0 \
  kubernetes_validate==1.20.0

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
