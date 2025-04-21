
        # -*- coding:utf-8 -*-
        
import json
import os
import re
import sys
import argparse
import time
import requests
import json

        
import logging
logging.basicConfig(level = logging.INFO)
LOG = logging.getLogger("openrouterai")

        
        
def read_args():
    parse = argparse.ArgumentParser()
    parse.add_argument('-p', '--placeholder', help='The Placeholder of Python Script.', type=str, required=False)
    args = parse.parse_args()
    return args
        
        
class OpenRouterAI(object):
    def __init__(self, placeholder):
        self.placeholder = placeholder
        
    def log_properties(self):
        LOG.info(self.__dict__)
        
    def run(self):
        self.log_properties()
        start = time.time()
        LOG.info(f"Start: {start}")
        key = "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"
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {key}",
                "HTTP-Referer": "cyberpi.tech", # Optional. Site URL for rankings on openrouter.ai.
                "X-Title": "Eva", # Optional. Site title for rankings on openrouter.ai.
            },
            data=json.dumps({
                "model":"deepseek/deepseek-r1-zero:free", # Optional
                "messages": [
                {
                    "role": "user",
                    "content": "1+1=?"
                }
                ]
            })
        )
        LOG.info(f"response: {response.json()}")
        LOG.info(f"cost: {time.time() - start}s")

    

            
        
if __name__ == '__main__':
    args = read_args()
        

    instance = OpenRouterAI(placeholder=args.placeholder)
    instance.run()
    
        