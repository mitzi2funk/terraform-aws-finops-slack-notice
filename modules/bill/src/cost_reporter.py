import boto3
import json
import datetime
import urllib3
import os
from decimal import Decimal, ROUND_HALF_UP

# --- 設定エリア ---
SECRET_NAME = "finops_commons"
SECRET_KEY = "SlackWebhookURL_cost"
EXCHANGE_RATE = Decimal('150.0')
MENTION_ALL = '<!channel>'
MENTION_OPS = '<@YOUR_SLACK_USER_ID>' # 担当者
# ----------------

def get_secret(region_name):
    client = boto3.client("secretsmanager", region_name=region_name)
    try:
        response = client.get_secret_value(SecretId=SECRET_NAME)
        secrets = json.loads(response['SecretString'])
        return secrets[SECRET_KEY]
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise e

def get_account_info():
    try:
        # アカウントIDの取得
        sts = boto3.client('sts')
        account_id = sts.get_caller_identity()['Account']
        
        # アカウント名の取得
        iam = boto3.client('iam')
        aliases = iam.list_account_aliases()['AccountAliases']
        account_name = aliases[0] if aliases else "No_Alias"
        
        return f"{account_name} ({account_id})"
    except Exception as e:
        print(f"Error retrieving account info: {e}")
        return "Unknown_Account"


def lambda_handler(event, context):
    current_region = os.environ.get('AWS_REGION', 'ap-northeast-1')

    ce = boto3.client('ce', region_name='us-east-1')
    http = urllib3.PoolManager()

    # 1. 動的情報の取得
    account_info = get_account_info()

    # 2. 期間設定
    today = datetime.date.today()
    first_day_this_month = today.replace(day=1)
    last_day_last_month = first_day_this_month - datetime.timedelta(days=1)
    first_day_last_month = last_day_last_month.replace(day=1)
    
    start_date = first_day_last_month.strftime('%Y-%m-%d')
    end_date = first_day_this_month.strftime('%Y-%m-%d')
    
    # 3. コスト取得
    try:
        response = ce.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
    except Exception as e:
        print(f"CE API Error: {e}")
        return {"status": "error", "message": str(e)}

    # 4. データ集計と降順ソート
    total_usd = Decimal('0.0')
    services_data = []
    
    for group in response['ResultsByTime'][0]['Groups']:
        amount = Decimal(group['Metrics']['UnblendedCost']['Amount'])
        service_name = group['Keys'][0]
        total_usd += amount
        if amount > Decimal('0.01'):
            services_data.append({"name": service_name, "amount": amount})

    services_data = sorted(services_data, key=lambda x: x['amount'], reverse=True)
    services_detail = [f"・{item['name']}: ${item['amount'].quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)}" for item in 
    total_jpy = total_usd * EXCHANGE_RATE

    """
    # --- 📊 4. QuickChart用のデータ整形とURL生成 ---
    chart_labels = []
    chart_data = []
    other_amount = 0.0

    # グラフが見やすくなるよう上位5件と「Others」に分割
    for i, item in enumerate(services_data):
        if i < 5:
            # ラベルが長すぎないように接頭辞をカット
            short_name = item['name'].replace("Amazon Elastic Compute Cloud - Compute", "EC2")\
                                     .replace("Amazon Relational Database Service", "RDS")\
                                     .replace("Amazon Simple Storage Service", "S3")\
                                     .replace("Amazon Elastic Container Service", "ECS")\
                                     .replace("Amazon EC2 Container Registry (ECR)", "ECR")\
                                     .replace("Amazon ", "")\
                                     .replace("AWS ", "")
            chart_labels.append(short_name)
            chart_data.append(round(item['amount'], 2))
        else:
            other_amount += item['amount']

    if other_amount > 0:
        chart_labels.append("Others")
        chart_data.append(round(other_amount, 2))

    # QuickChart (Chart.js) の設定オブジェクト
    chart_config = {
        "type": "doughnut", # ドーナツグラフ
        "data": {
            "labels": chart_labels,
            "datasets": [{"data": chart_data}]
        },
        "options": {
            "plugins": {
                "legend": {"position": "right"}, # 凡例を右側に配置
                "datalabels": {
                    "color": "#fff",
                    "font": {"weight": "bold"}
                }
            }
        }
    }
    
    # JSON文字列化してURLエンコード
    chart_config_str = json.dumps(chart_config)
    encoded_config = urllib.parse.quote(chart_config_str)
    # 背景白(bkg=white)、幅600、高さ300で画像URLを生成
    chart_url = f"https://quickchart.io/chart?c={encoded_config}&w=600&h=300&bkg=white"
    # ---------------------------------------------
    """

    # 5. Slackメッセージ構築 (Block Kit)
    webhook_url = get_secret(current_region)
    
    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "📢 AWS確定請求額通知 (前月分)"}
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn", 
                "text": f"*担当者:* {MENTION_ALL} {MENTION_OPS}\n*対象アカウント:* `{account_info}`\n*対象期間:* {start_date} 〜 {last_day_last_month.strftime('%Y-%m-%d')}"
            }
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*合計 (USD):*\n${total_usd.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)}"}, # ★丸め処理
                {"type": "mrkdwn", "text": f"*合計 (JPY概算):*\n¥{int(total_jpy):,}"}
            ]
        },
        # 📊 ここにグラフ画像ブロックを追加
        # {
        #     "type": "image",
        #     "title": {
        #         "type": "plain_text",
        #         "text": "コスト内訳グラフ",
        #         "emoji": True
        #     },
        #     "image_url": chart_url,
        #     "alt_text": "Cost Breakdown Chart"
        # },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "*サービス別内訳 (上位15項目):*\n" + "\n".join(services_detail[:15])}
        }
    ]

    # 6. Slack送信
    try:
        req = http.request(
            'POST',
            webhook_url,
            body=json.dumps({"blocks": blocks}),
            headers={'Content-Type': 'application/json'}
        )
        return {"status": "success", "http_code": req.status}
    except Exception as e:
        print(f"Slack post error: {e}")
        return {"status": "error", "message": str(e)}
