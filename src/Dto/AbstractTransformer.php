<?php

declare(strict_types=1);

namespace App\Dto;

abstract class AbstractTransformer implements TransformerObjectsInterface, TransformerObjectInterface
{
    public function transform(): AbstractDto
    {
        throw new \Exception(
            'The method must be implemented in an inheritor class'
        );
    }

    public function transformFromObject($object): AbstractDto
    {
        throw new \Exception(
            'The method must be implemented in an inheritor class'
        );
    }

    public function transformFromObjects(iterable $objects): iterable
    {
        $dto = [];

        foreach ($objects as $object) {
            $dto[] = $this->transformFromObject($object);
        }

        return $dto;
    }
}