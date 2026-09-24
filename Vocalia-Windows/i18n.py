"""Static UI translations. Recording contents are never translated or uploaded."""
import json
from pathlib import Path
LANGUAGES=[('es','Español'),('en','English'),('de','Deutsch'),('fr','Français'),('zh','简体中文'),('pt','Português')]
CATALOG=json.loads((Path(__file__).parent/'ui-translations.json').read_text(encoding='utf8'))
def normalize(language):
    code=(language or 'en').replace('_','-').split('-')[0]
    return code if code in dict(LANGUAGES) else 'en'
def tr(text,language):
    return CATALOG.get(text,{}).get(normalize(language),text)
