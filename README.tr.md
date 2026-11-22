# Redmine Plugin Update

Eklenti yönetim sayfasından git adresiyle eklenti ekler, günceller ve kaldırır.

[English](README.md)

## Yenilikler

* 0.1.0: İlk sürüm. Ayrıntılar [CHANGELOG](CHANGELOG.md) dosyasında.

## Ne yapar

* Yönetim → Eklentiler sayfasında git adresi yazarak eklenti eklersiniz.
* Git kopyası olan her eklentinin yanında Güncelle düğmesi vardır. O klasörde `git pull --ff-only` çalışır.
* Her eklentinin yanında Kaldır düğmesi vardır. Klasör kenara alınır, ardından Redmine yeniden başlar.
* Ekleme, güncelleme veya kaldırma başarılı olunca ayarlardaki yeniden başlatma komutu çalışır. Varsayılan `docker restart redmine-redmine-1` komutudur.
* Klonlama, çekme veya yeniden başlatma komutu hata verirse dosya değişikliği geri alınır. Hata `log/redmine_plugin_update.log` dosyasına ve Redmine loguna yazılır.
* Yerel değişikliği olan eklenti güncellenmez.
* `init.rb` içermeyen depo ve zaten yüklü olan eklenti geri silinir.

## Redmine sürümü

* 4.2.x ~ 6.x

Veritabanı göçü ve ek gem gerekmez. Redmine'ı çalıştıran kullanıcıda git olmalı ve bu kullanıcı `plugins` klasörüne yazabilmelidir.

## Kurulum

1. Redmine `plugins` dizininde:

```bash
git clone https://github.com/oten52/Redmine.PluginUpdate.git
```

Klasör adı `Redmine.PluginUpdate` olarak kalabilir.

2. Redmine'ı yeniden başlatın.

3. Yönetim → Eklentiler → Plugin Güncelle → Yapılandır. Yeniden başlatma komutu konteynerin içinde çalışır. Resmi imajda `docker` ve çoğu zaman `git` yoktur. Git yoksa güncelleme yapılmaz. Docker yoksa dosya değişikliği kalır; sunucuda `docker restart redmine-redmine-1` çalıştırırsınız. Eklenti klasörüne konteyner kullanıcısının yazma izni olmalıdır.

## Kaldırma

1. Eklentiyi Yönetim → Eklentiler sayfasından kaldırın veya `Redmine.PluginUpdate` klasörünü silin.
2. Redmine'ı yeniden başlatın.

## Yazar

Niltek Arge — https://github.com/oten52

## Lisans

GNU General Public License v3.0 veya sonrası. Ayrıntı için [LICENSE](LICENSE).

Bu eklentiyi değiştirip dağıtırsanız telif bildirimlerini koruyun, değişikliklerinizi belirtin ve
sürümünüzü aynı lisansla dağıtın.
