Для создания инфраструктуры необходимо выполнить набор команд:

$ git clone https://github.com/kravzo/sf-django-pg-terraform-ansible

$ cd sf-django-pg-terraform-ansible

$ ssh-keygen -t rsa

$ cp ~/.ssh/id_rsa* ./

В файл sf-django-pg-terraform-ansible/terraform/main.tf необходимо добавить реквизиты YandexCloud

$ cd terraform && terraform init && terraform apply

В результате выполнения команд будет создан набор серверов

$ cd ../ansible && ansible-playbook -i ../inventory.ini -u ubuntu ansible_playbook.yml

Результатом выполнения данной команды будет установка необходимого для дальнейшей работы ПО на созданных серверах.
